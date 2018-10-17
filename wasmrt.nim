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
    var lastChar = '\0'
    for c in s:
        if c in {' ', '\n', '\t'}:
            needsBreak = true
        else:
            if c == '$' and escapeDollar:
                result.add("$$")
            elif c in alpha:
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

g._nimmu = () => b = new Int8Array(q.buffer);

g._nimsj = a => {
    var s = '';
    while (b[a]) s += String.fromCharCode(b[a++]);
    return s
};

W.instantiate(m, {env: o}).then(m => {
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

N_LIB_EXPORT size_t fwrite(const void *ptr, size_t size, size_t nmemb, void *stream) {
  return 0;
}


""".}
proc consoleWarn(a: cstring) {.importwasm: "if(typeof console != 'undefined' && console.warn != undefined) console.warn(_nimsj($0))".}

proc flockfile(f: pointer) {.exportc.} = discard
proc funlockfile(f: pointer) {.exportc.} = discard

proc exit(code: cint) {.exportc.} =
  consoleWarn "exit called, ignoring"

proc fflush(stream: pointer): cint {.exportc.} =
  consoleWarn "fflush called, ignoring"

proc fputc(c: cint, stream: pointer): cint {.exportc.} =
  consoleWarn "fputc called, ignoring"

proc munmap(a: pointer, len: csize): cint {.exportc.} =
  consoleWarn "munmap called, ignoring"


const wasmPageSize = 64 * 1024
proc wasmMemorySize(i: int32): int {.importc: "__builtin_wasm_memory_size", nodecl.}
proc wasmMemoryGrow(b: int): int {.importc: "__builtin_wasm_grow_memory", nodecl.}

proc jsLog(s: cstring, i: int) {.importc, codegenDecl: "$# $#$# __asm__(\"2;console.log(_nimsj($$0), $$1)\")".}
proc jsMemIncreased() {.importc, codegenDecl: "$# $#$# __asm__(\"0;_nimmu()\")".}

var memStart, totalMemory: uint

proc wasmAlloc(block_size: int): pointer {.inline.} =
  if totalMemory == 0:
    totalMemory = cast[uint](wasmMemorySize(0)) * wasmPageSize
    memStart = totalMemory

  result = cast[pointer](memStart)

  let availableMemory = totalMemory - memStart
  inc(memStart, block_size)

  if availableMemory < cast[uint](block_size):
    let wasmPagesToAllocate = block_size div wasmPageSize + 1
    let oldPages = wasmMemoryGrow(wasmPagesToAllocate)
    if oldPages < 0:
      return nil

    inc(totalMemory, wasmPagesToAllocate * wasmPageSize)
    jsMemIncreased()

proc mmap(a: pointer, len: csize, prot, flags, fildes: cint, off: int): pointer {.exportc.} =
  if a != nil:
    consoleWarn("mmap called with wrong arguments")
  wasmAlloc(len)


GC_disable()

