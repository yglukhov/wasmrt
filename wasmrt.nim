import macros, strutils
import wasmrt/minify

const wasmExportCodegenDecl = when defined(cpp):
                  "extern \"C\" __attribute__ ((visibility (\"default\"))) $# $#$#"
                else:
                  "__attribute__ ((visibility (\"default\"))) $# $#$#"

macro exportwasm*(p: untyped): untyped =
  expectKind(p, nnkProcDef)
  result = p
  result.addPragma(ident"exportc")
  result.addPragma(newColonExpr(ident"codegenDecl", newLit(wasmExportCodegenDecl)))

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

type
  JSRef* = ptr object
  JSObj* {.inheritable.} = object
    o*: JSRef

proc isNil*(o: JSObj): bool {.inline.} = o.o.isNil

proc retTypeSig(t: typedesc, prop, meth: bool, numArgs: int): string =
  when t is (JSRef|JSObj):
    if prop:
      if numArgs > 0: "p" # 210
      else: "m" # 200
    elif meth: "q" # 211
    else: "n" # 201
  elif t is string:
    if prop:
      if numArgs > 0: "v" # 310
      else: "s" # 300
    elif meth: "w" # 311
    else: "t" # 301
  elif t is void:
    if prop:
      if numArgs > 1: "f" # 012
      else: "c" # 002
    elif meth: "e" # 011
    else: "b" # 001
  else:
    if prop:
      if numArgs > 0: "j" # 110
      else: "g" # 100
    elif meth: "k" # 111
    else: "h" # 101

template toWasm[T](a: T): auto =
  when a is string:
    cstring(a)
  elif a is JSObj:
    a.o
  else:
    a

template toWasmType(t: typedesc): typedesc =
  when t is void:
    void
  else:
    typeof(toWasm(default(t)))

var id {.compiletime.} = 1

macro importwasmAux2(body: string, p: untyped, argSig: static[string]): untyped =
  expectKind(p, nnkProcDef)

  let wrapper = newProc(procType = nnkTemplateDef)
  wrapper[0] = copyNimTree(p[0])
  wrapper.params = copyNimTree(p.params)
  let nameid = ident($p.name & "_nimwasmimport_" & $id)
  inc id
  # echo treeRepr(p)
  p[0] = nameid
  let args = p.params
  let retType = args[0] or ident"void"
  args[0] = newCall(bindSym"toWasmType", retType)
  var argid = 0
  for i in 1 ..< args.len:
    args[i][^2] = newCall(bindSym"toWasmType", args[i][^2])
    for j in 0 .. args[i].len - 3:
      args[i][j] = ident("wasm_arg_dummy_" & $argid)
      inc argid

  let call = newCall(nameid)
  for _, n, _, _ in arguments(wrapper.params):
    call.add(newCall(bindSym"toWasm", n))

  # wrapper.addPragma(ident"inline")
  # wrapper.addPragma(newColonExpr(ident"stackTrace", ident"off"))

  p.addPragma(ident"importc")
  inc id
  p.addPragma(newColonExpr(ident"codegenDecl", newLit("$# $#$# __asm__(\"^" & argSig & escapeJs(body.strVal.minifyJs, "$$") & "\")")))

  wrapper.body = quote do:
    when `retType` is void:
      `call`
    elif `retType` is JSObj:
      `retType`(o: `call`)
    else:
      `call`

  result = quote do:
    `p`
    `wrapper`

  # echo "R: ", repr result

proc joins(a: varargs[string]): string = a.join("")

proc argSig(t: typedesc): string =
  when t is (string|cstring): "s"
  elif t is (JSRef|JSObj): "o"
  else: "R"

proc numArgsSig(a: int): string {.compileTime.} =
  const maxArgs = ord('}') - ord('0')
  doAssert(a < maxArgs, "Number of arguments can not exceed " & $maxArgs)
  $char(a + ord('0'))

proc importwasmAux(body: string, p: NimNode, raw, prop, meth: bool): NimNode =
  p.expectKind(nnkProcDef)
  var numArgs = 0
  for _, _, _, _ in p.params.arguments:
    inc numArgs

  let nas = numArgsSig(numArgs)
  var sig: NimNode
  if raw:
    sig = newLit("a" & nas)
  else:
    let retType = p.params[0] or ident"void"
    sig = newCall(bindSym"joins", newCall(bindSym"retTypeSig", retType, newLit(prop), newLit(meth), newLit(numArgs)), newLit(nas))
    for _, _, t, _ in arguments(p.params):
      sig.add(newCall(bindSym"argSig", t))
  result = newCall(bindSym"importwasmAux2", newLit(body), p, sig)

proc parseArgs(n: NimNode, v: NimNode): (NimNode, string) =
  if v.len == 0:
    (n, $n.name)
  else:
    (v[0], n.strVal)

macro importwasmp*(a1: untyped, more: varargs[untyped]): untyped =
  # Import property from js to wasm
  # Void procs are setters
  # ```
  # proc document(): JSObj {.importwasmp.} # js: return document
  # proc document(o: JSObj) {.importwasmp.} # js: document = o
  # proc document(w: JSObj): JSObj {.importwasmp.} # js: return w.document
  # proc document(w, o: JSObj) {.importwasmp.} # js: w.document = o
  # ```
  let (b, n) = parseArgs(a1, more)
  result = importWasmAux(n, b, false, true, false)

macro importwasmm*(a1: untyped, more: varargs[untyped]): untyped =
  # Import method from js to wasm
  # ```
  # proc getElementById(d: JSObj, id: cstring): JSObj {.importwasmm.} # js: return d.getElementById(id)
  # ```
  let (b, n) = parseArgs(a1, more)
  result = importWasmAux(n, b, false, false, true)

macro importwasmf*(a1: untyped, more: varargs[untyped]): untyped =
  # Import function from js to wasm
  # ```
  # proc alert(t: cstring) {.importwasmf.} # js: alert(t)
  # ```
  let (b, n) = parseArgs(a1, more)
  result = importWasmAux(n, b, false, false, false)

macro importwasmraw*(name: string, b: untyped): untyped =
  # Import raw chunk of js code to wasm
  # ```
  # proc myfunction(t: cstring) {.importwasmraw: """
  #   var d = document;
  #   var e = d.getElementById(_nimsj($0));
  #   return _nimok(e);
  #   """.}
  # ```
  # Refer to args with `$NUM`, NUM starting from 0.
  # You can use JS helpers exposed by wasmrt, such as _nimo, _nimok, _nimsj, etc.
  result = importWasmAux(name.strVal, b, true, false, false)

proc copyAux(r: JSRef): uint32 {.importwasmf: "_nimok".}
proc copy(r: JSRef): JSRef {.inline, stackTrace: off.} = cast[JSRef](copyAux(r))

proc delete*(r: JSRef) {.importwasmraw: "_nimo[$0] = _nimoi; _nimoi = $0"}

proc `=copy`*(a: var JSObj, b: JSObj) =
  if a.o != nil:
    delete(a.o)
  if b.o.isNil:
    a.o = nil
  else:
    a.o = copy(b.o)

proc `=destroy`*(a: var JSObj) =
  if a.o != nil:
    delete(a.o)
    a.o = nil

when not defined(release):
  proc nimerr() {.exportwasm.} =
    writeStackTrace()
    raise newException(Exception, "")

proc to*(o: sink JSObj, T: typedesc[JSObj]): T {.inline.} =
  let r = o.o
  wasMoved(o)
  T(o: r)

# Return type
# R - 4 - 0 return void, 1 as is, 2 obj, 3 string
# F - 2 - 0 dont prepend first arg, 1 prepend
# A - 3 - 0 dont append args, 1 append args as call, 2 assign last arg
# RRRFAA

# RFA
# 000 a
# 001 b
# 002 c
# 010 d
# 011 e
# 012 f
# 100 g
# 101 h
# 102 i
# 110 j
# 111 k
# 112 l
# 200 m
# 201 n
# 202 o
# 210 p
# 211 q
# 212 r
# 300 s
# 301 t
# 302 u
# 310 v
# 311 w
# 312 x

# arg:
# R - pass as is
# o - convert to object
# s - convert to string

const initCode = (""";
var W = WebAssembly, f = W.Module.imports(m), o = {}, g = globalThis, q, b;
for (i of f) {
  var n = i.name;
  if (n[0] == '^') {
    var r = n[1],
    p = n.charCodeAt(2)-48,
    a='',
    b = n.substring(r=='a'?3:p+3),
    w = (a, t) => t=='o'?`_nimo[${a}]`:t=='s'?`_nimsj(${a})`:a,
    v = i => w('$' + i, n[i + 3]),
    j = t => t.includes(r)|0,
    M = j('defjklpqrvwx'), // Prepend first arg
    O = j('mnopqr'), // Return obj
    S = j('stuvwx'); // Return string

    for(I=0;I<p;++I)a+=(I?',$':'$')+I;

    if (j('behknqtw')) { // have arguments
      b += '(';
      for (I = M; I < p; ++I)
        b += (I-M ? ',' : '') + v(I);
      b += ')'
    }
    if (M)
      b = v(0) + '.' + b;
    if (j('cfilorux'))
      b += '=' + v(p-1);
    if (O)
      b = `_nimok(${b})`;
    if (S)
      b = `_nimem_s(${b})`;
    if (O|S|j('ghijkl'))
      b = 'return ' + b;
    o[n] = new Function(a, b)
  }
  else
    console.warn("Undefined external symbol: ", n),
""" & (if not defined(release): """o[n] = new Function('', 'console.error("Undefined symbol called: ' + n + '"); _nime.nimerr()');"""
      else: """o[n] = new Function('', 'throw new Error("Undefined symbol called: ' + n + '")');""") &
"""
}

g._nimc = '';
g._nimo = [null];
g._nimoi = -1;

// function _nimok(object): int
// Store object in _nimo array, and return index to it, to be used from wasm
g._nimok = o => {
  if (!o) return 0;
  var r;
  if (_nimoi < 0)
    r = _nimo.length;
  else
    _nimoi = _nimo[r = _nimoi];
  _nimo[r] = o;
  return r
};

g._nimmu = () => g._nima = b = new Int8Array(q.buffer);

// function _nimsj(address): string
// Create JS string from null-terminated string at `address`
g._nimsj = a => {
  var s = '';
  while (b[a]) s += String.fromCharCode(b[a++]);
  return s
};

// function _nims(address, length): string
// Create JS string from string at `address` with `length`
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
    var m = new Int8Array(q.buffer, a);
    for (i = 0; i < L; ++i)
      m[i] = s.charCodeAt(i)
  }
};

// function _nimwi(int32Array, address)
// Write `int32Array` at `address`
g._nimwi = (v, a) => new Int32Array(q.buffer, a).set(v);

// function _nimwf(float32Array, address)
// Write `float32Array` at `address`
g._nimwf = (v, a) => new Float32Array(q.buffer, a).set(v);

// function _nimwd(float64Array, address)
// Write `float64Array` at `address`
g._nimwd = (v, a) => new Float64Array(q.buffer, a).set(v);

W.instantiate(m, {env: o}).then(m => {
  g._nimm = m;
  g._nime = m.exports;
  q = _nime.memory;
  _nimmu();
  _nime.NimMain();
})
""").minifyJs().escapeJs()

{.emit: ["""
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

N_LIB_PRIVATE void* memmem(const void *l, size_t l_len, const void *s, size_t s_len) {
  register char *cur, *last;
  const char *cl = (const char *)l;
  const char *cs = (const char *)s;

  /* we need something to compare */
  if (l_len == 0 || s_len == 0)
    return NULL;

  /* "s" must be smaller or equal to "l" */
  if (l_len < s_len)
    return NULL;

  /* special case where s_len == 1 */
  if (s_len == 1)
    return memchr(l, (int)*cs, l_len);

  /* the last position where its possible to find "s" in "l" */
  last = (char *)cl + l_len - s_len;

  for (cur = (char *)cl; cur <= last; cur++)
    if (cur[0] == cs[0] && memcmp(cur, cs, s_len) == 0)
      return cur;

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

N_LIB_PRIVATE double fmod(double x, double y) {
  return x - trunc(x / y) * y;
}

N_LIB_PRIVATE float fmodf(float x, float y) {
  return fmod(x, y);
}

"""].}

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

proc isNodejsAux(): bool {.importwasmp: "typeof process!='undefined'".}

proc nodejsWriteToStream(s: int, b: pointer, l: int) {.importwasmraw:"process[$0?'stderr':'stdout'].write(_nims($1,$2))".}

proc consoleWarn(a: cstring) {.importwasmf: "console.warn".}

proc consoleAppend(b: pointer, l: int) {.importwasmraw: "_nimc += _nims($0,$1)".}
proc consoleFlush(s: int) {.importwasmraw: "console[$0?'error':'log'](_nimc); _nimc = ''".}

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
  when not defined(release):
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
  when not defined(release):
    consoleWarn "munmap called, ignoring"

proc dlopen(a: cstring): cint {.exportc.} =
  when defined(release):
    exit(-1)
  else:
    echo "dlopen(", a, ")"
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

proc jsMemIncreased() {.importwasmf: "_nimmu".}

var memStart, totalMemory: uint

proc wasmAlloc(block_size: uint): pointer {.inline.} =
  if totalMemory == 0:
    totalMemory = cast[uint](wasmMemorySize(0)) * wasmPageSize
    memStart = totalMemory

  result = cast[pointer](memStart)

  let availableMemory = totalMemory - memStart
  memStart += block_size

  if availableMemory < block_size:
    let wasmPagesToAllocate = block_size div wasmPageSize + 1
    let oldPages = wasmMemoryGrow(int32(wasmPagesToAllocate))
    if oldPages < 0:
      return nil

    totalMemory += wasmPagesToAllocate * wasmPageSize
    jsMemIncreased()

proc mmap(a: pointer, len: csize_t, prot, flags, fildes: cint, off: int): pointer {.exportc.} =
  if unlikely a != nil:
    when not defined(release):
      consoleWarn("mmap called with wrong arguments")
    return nil

  wasmAlloc(len)

# Suppress __wasm_call_ctors
# https://stackoverflow.com/questions/72568387/why-is-an-objects-constructor-being-called-in-every-exported-wasm-function
proc initialize() {.stackTrace: off, exportc: "_initialize", codegenDecl: wasmExportCodegenDecl.} =
  proc ctors() {.importc: "__wasm_call_ctors".}
  ctors()

when not defined(gcDestructors):
  GC_disable()

import wasmrt/libc
import std/compilesettings

# Compiler and linker options
static:
  # Nim will pass -lm and -lrt to linker, so we provide stubs, by compiling empty c file into nimcache/lib*.a, and pointing
  # the linker to nimcache
  const nimcache = querySetting(nimcacheDir)
  {.passL: "-L" & nimcache.}
  var compilerPath = querySetting(ccompilerPath)
  if compilerPath == "":
    compilerPath = "clang"
  when defined(windows):
    discard staticExec("mkdir " & nimcache)
  else:
    discard staticExec("mkdir -p " & nimcache)
  discard staticExec(compilerPath & " -c --target=wasm32-unknown-unknown-wasm -o " & nimcache & "/libm.a -x c -", input = "\n")
  discard staticExec(compilerPath & " -c --target=wasm32-unknown-unknown-wasm -o " & nimcache & "/librt.a -x c -", input = "\n")
