import macros

macro exportwasm*(p: untyped): untyped =
    expectKind(p, nnkProcDef)
    result = p
    result.addPragma(newIdentNode("exportc"))
    when defined(cpp):
        result.addPragma(newColonExpr(newIdentNode("codegenDecl"), newLit("extern \"C\" __attribute__ ((visibility (\"default\"))) $# $#$#")))
    else:
        result.addPragma(newColonExpr(newIdentNode("codegenDecl"), newLit("__attribute__ ((visibility (\"default\"))) $# $#$#")))

proc escape(s: string, escapeDollar = true): string {.compileTime.} =
    result = ""
    var needsBreak = false

    const alpha = {'A' .. 'Z', 'a' .. 'z'}
    const digits = {'0' .. '9'}
    var lastChar = '\0'
    for c in s:
        if c in {' ', '\n', '\t'}:
            needsBreak = true
        else:
            if c == '$' and escapeDollar:
                result.add("$$")
            elif c in alpha or c in digits:
                if needsBreak and lastChar in alpha:
                    result.add(' ')
                result.add(c)
            else:
                result.addEscapedChar(c)
            needsBreak = false
            lastChar = c

proc quote(s: string): string {.compileTime.} =
    result = "\"" & escape(s, false) & "\""

macro importwasm*(body: string, p: untyped): untyped =
    expectKind(p, nnkProcDef)
    result = p

    var argCount = 0
    for a in 1 ..< p.params.len:
        argCount += p.params[a].len - 2

    result.addPragma(newIdentNode("importc"))
    result.addPragma(newColonExpr(newIdentNode("codegenDecl"), newLit("$# $#$# __asm__(\"" & $argCount & ";" & escape(body.strVal) & "\")")))

const initCode = """;
var W = WebAssembly, f = W.Module.imports(m), o = {}, g = typeof window == 'undefined' ? global : window, q, b;
for (i in f) {
    var a = '', n = f[i].name, c = parseInt(n);
    if (isNaN(c))
        console.warn("Undefined external symbol: ", n),
        o[n] = new Function('', 'throw new Error("Undefined symbol called:  ' + n + '")');
    else {
        for (j = 0; j < c; ++j) {
            if (j) a += ',';
            a += '$' + j
        }
        o[n] = new Function(a, n)
    }
}

g._nimc = [];

g._nimmu = () => b = new Int8Array(q.buffer);

g._nimsj = a => {
    var s = '';
    while (b[a]) s += String.fromCharCode(b[a++]);
    return s
};

g._nims = (a, l) => {
    var s = '';
    while (l--) s += String.fromCharCode(b[a++]);
    return s
};

W.instantiate(m, {env: o}).then(m => {
    g._nimm = m;
    q = m.exports.memory;
    _nimmu();
    m.exports['-']()
})
""".quote()

{.emit: """
#define NIM_WASM_EXPORT N_LIB_EXPORT __attribute__((visibility ("default")))

NIM_WASM_EXPORT void nimWasmMain() __asm__("-");
void nimWasmMain() {
    void NimMain();
    NimMain();
}

NIM_WASM_EXPORT const char __nimWasmInit __asm__(""" & initCode & """) = 0;

N_LIB_EXPORT void* memcpy(void* a, void* b, size_t s) {
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

N_LIB_EXPORT void* memset(void* a, int b, size_t s) {
    char* aa = (char*)a;
    while(s) {
        --s;
        *aa = b;
        ++aa;
    }
    return a;
}

#ifdef __cplusplus

namespace std {
  typedef void (*terminate_handler)();
  terminate_handler set_terminate(terminate_handler h) noexcept {
    return NULL;
  }
}

#endif

""".}

{.pragma: wasmexport, exportc, dynlib.}

proc isNodejsAux(): bool {.importwasm:"return typeof process != 'undefined'".}

proc nodejsWriteStdout(b: pointer, l: int) {.importwasm:"process.stdout.write(_nims($0, $1))".}

proc consoleWarn(a: cstring) {.importwasm: "console.warn(_nimsj($0))".}

proc jsLog(s: cstring, i: int) {.importwasm: "console.log(_nimsj($0), $1)".}

proc consoleAppend(b: pointer, l: int) {.importwasm: "_nimc.push(_nims($0, $1))".}
proc consoleFlush() {.importwasm: "console.log(_nimc.join('')); _nimc = []".}

proc fwrite(p: pointer, sz, nmemb: csize, stream: pointer): csize {.wasmexport.} =
  if cast[int](stream) == 0:
    # stdout
    let fzs = int(sz * nmemb)
    if isNodejsAux():
      nodejsWriteStdout(p, fzs)
    else:
      consoleAppend(p, fzs)

  else:
    consoleWarn("Attempted to write to wrong stream")

proc flockfile(f: pointer) {.wasmexport.} = discard
proc funlockfile(f: pointer) {.wasmexport.} = discard

proc exit(code: cint) {.wasmexport.} =
  consoleWarn "exit called, ignoring"

proc fflush(stream: pointer): cint {.wasmexport.} =
  if cast[int](stream) == 0 and not isNodejsAux():
    consoleFlush()

proc fputc(c: cint, stream: pointer): cint {.wasmexport.} =
  if cast[int](stream) == 0:
    var buf = cast[uint8](c)
    if isNodejsAux():
      nodejsWriteStdout(addr buf, 1)
  else:
    consoleWarn "fputc called, ignoring"

proc munmap(a: pointer, len: csize): cint {.wasmexport.} =
  consoleWarn "munmap called, ignoring"


const wasmPageSize = 64 * 1024
proc wasmMemorySize(i: int32): int32 {.importc: "__builtin_wasm_memory_size", nodecl.}
proc wasmMemoryGrow(b: int32): int32 {.inline.} =
  when true:
    proc int_wasm_memory_grow(m, b: int32) {.importc: "__builtin_wasm_memory_grow", nodecl.}
    int_wasm_memory_grow(0, b)
  else:
    proc int_wasm_memory_grow(b: int32) {.importc: "__builtin_wasm_grow_memory", nodecl.}
    int_wasm_memory_grow(b)

proc wasmThrow(b: int32, p: pointer) {.importc: "__builtin_wasm_throw", nodecl.}
proc wasmGetException(b: int32): pointer {.importc: "__builtin_wasm_catch", nodecl.}

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

proc mmap(a: pointer, len: csize, prot, flags, fildes: cint, off: int): pointer {.wasmexport, dynlib.} =
  if a != nil:
    consoleWarn("mmap called with wrong arguments")
  wasmAlloc(len)

GC_disable()

when false:
  var emasmId {.compileTime.}: int

  proc emasmImpl(code, typ: string, args: NimNode): NimNode =
    result = newNimNode(nnkStmtList)
    let prc = newProc()
    prc.addPragma(newColonExpr(newIdentNode("importwasm"), newLit(code)))
    let s = genSym(nskProc, "emasm" & $emasmId)
    inc emasmId
    prc.name = s
    prc.params[0] = newIdentNode(typ)
    for i, a in args:
      prc.params.add(newIdentDefs(newIdentNode("arg" & $i), newCall("type", copyNimTree(a))))

    let c = newCall(s)
    for a in args: c.add(a)
    result.add(prc)
    result.add(c)

  macro EM_ASM_INT(code: static[string], args: varargs[untyped]): cint =
    result = emasmImpl(code, "cint", args)

  macro EM_ASM_DOUBLE(code: static[string], args: varargs[untyped]): cdouble =
    result = emasmImpl(code, "cdouble", args)

  discard EM_ASM_INT("console.log('hello', $0)", 123)
  echo "emasm returned: ", EM_ASM_INT("console.log('hello again', $0); return 156", 123)
  echo "emasm returned: ", int(EM_ASM_DOUBLE("console.log('hello again double', $0); return 1.56", 123))


  var myGlobal: int
  {.emit: """/*INCLUDESECTION*/

  int __cpp_exception = 0;
  """.}

  proc foo(a: int) =
    echo "foo"
    # try:
    echo "hi"
    var b: int
  #   {.emit: """
  #   try {
  #     if (`a` == 1) {
  #       __builtin_wasm_throw(__cpp_exception, &`myGlobal`);
  #     }
  #   }
  #   catch(...) {
  #     `b` = 5;
  #   }
  # """.}
    echo b
    # wasmThrow(0, addr myGlobal)
    # except:
    #   echo "except"
    # let e = wasmGetException(0)
    # try:
    #   echo "trying"
    #   raise newException(Exception, "hi")
    # except:
    #   echo "except"

  foo(1)
  foo(2)

