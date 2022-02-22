import macros
import wasmrt/minify

macro exportwasm*(p: untyped): untyped =
  expectKind(p, nnkProcDef)
  result = p
  result.addPragma(newIdentNode("exportc"))
  let cgenDecl = when defined(cpp):
                   "extern \"C\" __attribute__ ((visibility (\"default\"))) $# $#$#"
                 else:
                   "__attribute__ ((visibility (\"default\"))) $# $#$#"

  result.addPragma(newColonExpr(newIdentNode("codegenDecl"), newLit(cgenDecl)))

proc stripSinkFromArgType(t: NimNode): NimNode =
  result = t
  if result.kind == nnkBracketExpr and result.len == 2 and result[0].kind == nnkSym and $result[0] == "sink":
    result = result[1]

iterator arguments(formalParams: NimNode): tuple[idx: int, name, typ, default: NimNode] =
  formalParams.expectKind(nnkFormalParams)
  var iParam = 0
  for i in 1 ..< formalParams.len:
    let pp = formalParams[i]
    for j in 0 .. pp.len - 3:
      yield (iParam, pp[j], copyNimTree(stripSinkFromArgType(pp[^2])), pp[^1])
      inc iParam

macro importwasm*(body: string, p: untyped): untyped =
    expectKind(p, nnkProcDef)
    result = p

    var argString = ""
    for a in arguments(p.params):
        if a.idx != 0: argString &= ","
        argString &= $a.name

    var body = body.strVal
    when false:
      body = "try {" & body & "} catch(e) { _nime.nimerr() }"

    result.addPragma(newIdentNode("importc"))
    result.addPragma(newColonExpr(newIdentNode("codegenDecl"), newLit("$# $#$# __asm__(\"" & escapeJs("\"" & argString & "\";" & body.minifyJs, "$$") & "\")")))

when not defined(release):
  proc nimerr() {.exportwasm.} =
    raise newException(Exception, "")

const initCode = (""";
var W = WebAssembly, f = W.Module.imports(m), o = {}, g = typeof window == 'undefined' ? global : window, q, b;
for (i in f) {
  var a = '', n = f[i].name;
  if (n[0] == '"')
    o[n] = new Function(n.substring(1, n.indexOf('"', 1)), n);
  else
    console.warn("Undefined external symbol: ", n),
""" & (if not defined(release): """o[n] = new Function('', 'console.error("Undefined symbol called: ' + n + '"); _nime.nimerr()');"""
      else: """o[n] = new Function('', 'throw new Error("Undefined symbol called: ' + n + '")');""") &
"""
}

g._nimc = [];

g._nimmu = () => g._nima = b = new Int8Array(q.buffer);

// function _nimsj(address): string
// Create JS string from null-terminated string at `address`
g._nimsj = a => {
  var s = '';
  while (b[a]) s += String.fromCharCode(b[a++]);
  return s
};

// function _nims(address, length): string
// Create JS string from terminated string at `address` with `length`
g._nims = (a, l) => {
  var s = '';
  while (l--) s += String.fromCharCode(b[a++]);
  return s
};

// function _nimws(string, address, length)
// Write js string to buffer at `address` with `length`. The output is not null-terminated
g._nimws = (s, a, l) => {
  var L = s.length;
  L = L < l ? L : l;
  if (L) {
    var m = new Int8Array(g._nime.memory.buffer);
    for (i = 0; i < L; ++i)
      m[a + i] = s.charCodeAt(i);
  }
};

// function _nimwi(int32Array, address)
// Write `int32Array` at `address`
g._nimwi = (v, a) => new Int32Array(g._nime.memory.buffer).set(v, a >> 2);

// function _nimwd(float32Array, address)
// Write `float32Array` at `address`
g._nimwf = (v, a) => new Float32Array(g._nime.memory.buffer).set(v, a >> 2);

// function _nimwd(float64Array, address)
// Write `float64Array` at `address`
g._nimwd = (v, a) => new Float64Array(g._nime.memory.buffer).set(v, a >> 3);

W.instantiate(m, {env: o}).then(m => {
  g._nimm = m;
  g._nime = m.exports;
  q = _nime.memory;
  _nimmu();
  _nime.NimMain()
})
""").minifyJs().escapeJs()

{.emit: """
#define NIM_WASM_EXPORT N_LIB_EXPORT __attribute__((visibility ("default")))

int stdout = 0;
int stderr = 1;
static int dummyErrno = 0;

NIM_WASM_EXPORT const char __nimWasmInit __asm__(""" & '"' & initCode & """") = 0;

N_LIB_PRIVATE void* memcpy(void* a, const void* b, size_t s) {
  char* aa = (char*)a;
  char* bb = (char*)b;
  while(s) {
    --s;
    *aa = *bb;
    ++aa;
    ++bb;
  }
  return a;
}

N_LIB_PRIVATE void* memmove(void *dest, const void *src, size_t len) { /* Copied from https://code.woboq.org/gcc/libgcc/memmove.c.html */
  char *d = dest;
  const char *s = src;
  if (d < s)
    while (len--)
      *d++ = *s++;
  else {
    char *lasts = s + (len-1);
    char *lastd = d + (len-1);
    while (len--)
      *lastd-- = *lasts--;
  }
  return dest;
}

N_LIB_PRIVATE void* memchr(register const void* src_void, int c, size_t length) { /* Copied from https://code.woboq.org/gcc/libiberty/memchr.c.html */
  const unsigned char *src = (const unsigned char *)src_void;

  while (length-- > 0) {
    if (*src == c)
     return (void*)src;
    src++;
  }
  return NULL;
}

N_LIB_PRIVATE int memcmp(const void* a, const void* b, size_t s) {
  char* aa = (char*)a;
  char* bb = (char*)b;
  if (aa == bb) return 0;

  while(s) {
    --s;
    int ia = *aa;
    int ib = *bb;
    int r = ia - ib; // TODO: The result might be inverted. Verify against C standard.
    if (r) return r;
    *aa = *bb;
    ++aa;
    ++bb;
  }
  return 0;
}

N_LIB_PRIVATE void* memset(void* a, int b, size_t s) {
  char* aa = (char*)a;
  while(s) {
    --s;
    *aa = b;
    ++aa;
  }
  return a;
}

N_LIB_PRIVATE size_t strlen(const char* a) {
  const char* b = a;
  while (*b++);
  return b - a - 1;
}

N_LIB_PRIVATE char* strerror(int errnum) {
  return "strerror is not supported";
}

N_LIB_PRIVATE int* __errno_location() {
  return &dummyErrno;
}

N_LIB_PRIVATE char* strstr(char *haystack, const char *needle) {
  if (haystack == NULL || needle == NULL) {
    return NULL;
  }

  for ( ; *haystack; haystack++) {
    // Is the needle at this point in the haystack?
    const char *h, *n;
    for (h = haystack, n = needle; *h && *n && (*h == *n); ++h, ++n) {
      // Match is progressing
    }
    if (*n == '\0') {
      // Found match!
      return haystack;
    }
    // Didn't match here.  Try again further along haystack.
  }
  return NULL;
}
""".}

macro defDyncall(sig: static[string]): untyped =
  let callbackIdent = ident"callback"
  let callbackParams = newTree(nnkFormalParams)
  let callbackCall = newCall(callbackIdent)

  var params: seq[NimNode]
  for i, c in sig:
    let t = case c
      of 'v': ident"void"
      of 'i': ident"cint"
      of 'd': ident"cdouble"
      else: raise newException(AssertionDefect, "Unexpected signature: " & $c)

    if i == 0:
      params.add(t)
      callbackParams.add(t)
    else:
      let id = ident("arg" & $i)
      params.add(newIdentDefs(id, t))
      callbackParams.add(newIdentDefs(id, t))
      callbackCall.add(id)

  let callbackTy = newTree(nnkProcTy, callbackParams, newEmptyNode())
  callbackTy.addPragma(ident"cdecl")
  params.insert(newIdentDefs(callbackIdent, callbackTy), 1)

  result = newProc(ident("dyncall"), params, callbackCall)
  result.addPragma(newColonExpr(ident"exportc", newLit("_d" & sig)))
  result.addPragma(ident"dynlib")
  # echo repr result

proc defineDyncall*(sig: static[string]) =
  ## Call this function to make sure that the resulting wasm exposes
  ## _dsig function to make dynamic calls by function address.
  ## Calling this function with the same arguments more than once is a
  ## noop.
  defDyncall(sig)
  mixin dyncall
  var p = dyncall # Make sure nim doesn't dead-code-eliminate the generated func
  p = nil

proc isNodejsAux(): bool {.importwasm:"return typeof process != 'undefined'".}

proc nodejsWriteToStream(s: int, b: pointer, l: int) {.importwasm:"(s?process.stderr:process.stdout).write(_nims(b, l))".}

proc consoleWarn(a: cstring) {.importwasm: "console.warn(_nimsj(a))".}

proc consoleAppend(b: pointer, l: int) {.importwasm: "_nimc.push(_nims(b, l))".}
proc consoleFlush(s: int) {.importwasm: "(s?console.error:console.log)(_nimc.join('')); _nimc = []".}

proc fwrite(p: pointer, sz, nmemb: csize_t, stream: pointer): csize_t {.exportc.} =
  if cast[int](stream) in {0, 1}:
    # stdout
    let fzs = int(sz * nmemb)
    if isNodejsAux():
      nodejsWriteToStream(cast[int](stream), p, fzs)
    else:
      consoleAppend(p, fzs)
  else:
    consoleWarn("Attempted to write to wrong stream")

proc flockfile(f: pointer) {.exportc.} = discard
proc funlockfile(f: pointer) {.exportc.} = discard
proc ferror(f: pointer): cint {.exportc.} = discard

proc exit(code: cint) {.exportc.} =
  consoleWarn "exit called, ignoring"

proc fflush(stream: pointer): cint {.exportc.} =
  if cast[int](stream) in {0, 1} and not isNodejsAux():
    consoleFlush(cast[int](stream))

proc fputc(c: cint, stream: pointer): cint {.exportc.} =
  if cast[int](stream) == 0:
    var buf = cast[uint8](c)
    if isNodejsAux():
      nodejsWriteToStream(cast[int](stream), addr buf, 1)
  else:
    consoleWarn "fputc called, ignoring"

proc munmap(a: pointer, len: csize_t): cint {.exportc.} =
  consoleWarn "munmap called, ignoring"

proc dlopen(a: cstring): cint {.exportc.} =
  echo "dlopen(", a, ")"
  when defined(release):
    exit(-1)
  else:
    nimerr()

const wasmPageSize = 64 * 1024
proc wasmMemorySize(i: int32): int32 {.importc: "__builtin_wasm_memory_size", nodecl.}
proc wasmMemoryGrow(b: int32): int32 {.inline.} =
  when true:
    proc int_wasm_memory_grow(m, b: int32) {.importc: "__builtin_wasm_memory_grow", nodecl.}
    int_wasm_memory_grow(0, b)
  else:
    proc int_wasm_memory_grow(b: int32) {.importc: "__builtin_wasm_grow_memory", nodecl.}
    int_wasm_memory_grow(b)

# proc wasmThrow(b: int32, p: pointer) {.importc: "__builtin_wasm_throw", nodecl.}
# proc wasmGetException(b: int32): pointer {.importc: "__builtin_wasm_catch", nodecl.}

proc jsMemIncreased() {.importwasm: "_nimmu()".}

var memStart, totalMemory: uint

proc wasmAlloc(block_size: uint): pointer {.inline.} =
  if totalMemory == 0:
    totalMemory = cast[uint](wasmMemorySize(0)) * wasmPageSize
    memStart = totalMemory

  result = cast[pointer](memStart)

  let availableMemory = totalMemory - memStart
  memStart += block_size
  # inc(memStart, block_size)

  if availableMemory < block_size:
    let wasmPagesToAllocate = block_size div wasmPageSize + 1
    let oldPages = wasmMemoryGrow(int32(wasmPagesToAllocate))
    if oldPages < 0:
      return nil

    totalMemory += wasmPagesToAllocate * wasmPageSize
    jsMemIncreased()

proc mmap(a: pointer, len: csize_t, prot, flags, fildes: cint, off: int): pointer {.exportc.} =
  if a != nil:
    consoleWarn("mmap called with wrong arguments")
  wasmAlloc(len)

when not defined(gcDestructors):
  GC_disable()

import wasmrt/libc
