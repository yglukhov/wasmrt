import std/[macros, strutils, os, tables]
import wasmrt/minify

const wasmrtImportModuleName {.strdefine.} = "env"

macro exportwasm*(p: untyped): untyped =
  expectKind(p, nnkProcDef)
  result = p
  let name = $p.name
  let codegenPragma = "__attribute__ ((export_name (\"" & name & "\"))) $# $#$#"
  result.addPragma(newColonExpr(ident"codegenDecl", newLit(codegenPragma)))
  result.addPragma(ident"exportc")

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
  JSRef* = distinct pointer
  JSObj* {.inheritable, pure.} = object
    o*: JSRef
  JSString* = object of JSObj
  JSExternObjBase {.inheritable, pure, noinit, importc: "__externref_t", bycopy.} = object

  JSExternRef* = JSExternObjBase

macro parent(t: typedesc): untyped =
  let n = t.getType()[1]
  if sameType(n, bindSym"JSObj"):
    return bindSym"JSExternRef"
  else:
    let imp = n.getTypeImpl()
    imp.expectKind(nnkObjectTy)
    let base = imp[1][0]
    result = newTree(nnkObjectTy,
                    newEmptyNode(),
                    newTree(nnkOfInherit,
                            newTree(nnkBracketExpr, ident"JSExternObj", base)),
                    newEmptyNode())

type
  JSExternObj*[T] {.noinit, importc: "__externref_t", bycopy.} = parent(T)

type ExternRefTable {.importc.} = object
var globalRefs {.codegendecl: "static __externref_t $2[0]".}: ExternRefTable
proc wasmTableGrow(t: ExternRefTable, e: JSExternRef, by: cint): int32 {.importc: "__builtin_wasm_table_grow", nodecl.}
proc wasmTableSet(t: ExternRefTable, i: cint, e: JSExternRef) {.importc: "__builtin_wasm_table_set", nodecl.}
proc wasmTableGet(t: ExternRefTable, i: cint): JSExternRef {.importc: "__builtin_wasm_table_get", nodecl.}

proc nullExternRef(): JSExternRef {.importc: "__builtin_wasm_ref_null_extern", nodecl.}

proc globalRefsTab(): int =
  proc initGlobalRefsTab(): int =
    wasmTableGrow(globalRefs, nullExternRef(), 1)
  var g {.global.} = initGlobalRefsTab()
  g

var firstRef: int32 = -1
var refs: array[64 * 1024 div sizeof(int32), int32] # Occupies 64KB

proc storeRef(e: JSExternRef): int32 {.noinline.} =
  discard globalRefsTab()
  if firstRef < 0:
    result = wasmTableGrow(globalRefs, e, 1) # returns previous size
    refs[result + 1] = 1
  else:
    result = firstRef
    firstRef = refs[result]
    wasmTableSet(globalRefs, result, e)

proc createJSRef(e: JSExternRef): JSRef {.inline.} =
  cast[JSRef](storeRef(e))

converter toJSExternRef*(e: JSRef): JSExternRef =
  wasmTableGet(globalRefs, cast[int32](e))
# Return type
# 0IIIAARF
# F - 1 - 0 dont prepend first arg, 1 prepend
# R - 1 - 0 do nothing, 1 prepend "return"
# A - 2 - 0 dont append args, 1 append args as call, 2 assign last arg
# I - 3 - ID

proc retTypeSigA(r, f, a: int): int {.compileTime.} =
  (a shl 2) or (r shl 1) or (f shl 0)

proc retTypeR(t: typedesc): int =
  when t is void: 0
  else: 1

proc retTypeSig(t: typedesc, f, a: int): int =
  retTypeSigA(retTypeR(t), f, a)

proc retTypeSig(t: typedesc, prop, meth: bool, numArgs: int): int =
  let r = retTypeR(t)
  var f = 0
  var a = 0

  if prop:
    if (numArgs > 1 and r == 0):
      f = 1
      a = 2
    elif (numArgs > 0 and r != 0):
      f = 1
      a = 0
    else:
      f = 0
      a = 0
  elif meth:
    f = 1
    a = 1
  else:
    f = 0
    a = 1
  retTypeSigA(r, f, a)

template toWasm*(a: JSExternObj): auto = a
template toWasm*(a: JSExternRef): JSExternRef = a
template toWasm*(a: JSRef): JSExternRef = toJSExternRef(a)
template toWasm*[T: JSObj](a: T): JSExternObj[T] = JSExternObj[T](toJSExternRef(a.o))
template toWasm*(a: int|uint|int32|uint32|uint64|float32|float64|bool|pointer|ptr|enum|set): auto = a
# template toWasm*(p: proc {.cdecl.}): pointer = cast[pointer](p)

type
  JSExternFuncRef* {.importc: "typeof(void (*__funcref)())".} = object

template toWasm*(a: JSExternFuncRef): auto = a

template toWasmType(t: typedesc): typedesc =
  mixin toWasm
  when t is void:
    void
  else:
    typeof(toWasm(default(t)))

template toWasmWrapperType(t: typedesc): typedesc =
  when t is void:
    void
  elif t is JSRef:
    JSExternRef
  elif t is JSObj:
    JSExternObj[t] | t
  else:
    t

template wasmTypeSig(t: typedesc): string =
  when t is void: "v"
  elif toWasmType(t) is int|uint|int8|uint8|int16|uint16|int32|uint32|pointer|bool|ptr|enum|set: "i32"
  elif toWasmType(t) is int64|uint64: "i64"
  elif toWasmType(t) is float32|cfloat: "f32"
  elif toWasmType(t) is float64|float|cdouble: "f64"
  elif toWasmType(t) is JSExternRef|JSExternObj: "r"
  elif toWasmType(t) is JSExternFuncRef: "p"
  else:
    {.error: "Unexpected type: " & $t.}

var id {.compiletime.} = 1
type
  WasmIdKey = object
    body: string
    funSig: int
    numArgs: int

var wasmIdTable {.compiletime.} = initTable[WasmIdKey, TableRef[string, int]]()

proc genWasmId(body, typSig: string, funSig, numArgs: int): int =
  let key = WasmIdKey(body: body, funSig: funSig, numArgs: numArgs)
  var idTab = wasmIdTable.getOrDefault(key)
  var wasmId = 0
  if idTab.isNil:
    idTab = newTable[string, int]()
    idTab[typSig] = 0
    wasmIdTable[key] = idTab
  else:
    result = idTab.getOrDefault(typSig, -1)
    if result == -1:
      result = idTab.len
      doAssert(wasmId <= 16, "Too many wasm function overloads")
      idTab[typSig] = result

proc codegenDeclStr(rawBody: string): string =
  # returns value for codegendecl pragma of an imported function with raw body `s` (including arg sig)
  "__attribute__((import_module(\"" & wasmrtImportModuleName & "\"))) $# $#$# __asm__(\"^" & rawBody & "\")"

macro importwasmAux2(body, typSig: static[string], p: untyped, funSig, numArgs: static[int]): untyped =
  expectKind(p, nnkProcDef)

  let body = escapeJs(body.minifyJs, "$$")
  let wasmId = genWasmId(body, typSig, funSig, numArgs)
  let funSig = (wasmId.uint shl 4) or funSig.uint

  let argSig = "\\" & toOctal(funSig.char) & "\\" & toOctal(numArgs.char)

  let wrapper = newProc(procType = nnkProcDef)
  wrapper[0] = copyNimTree(p[0])
  let parms = copyNimTree(p.params)
  for i in 1 ..< parms.len:
    parms[i][^2] = newCall(bindSym"toWasmWrapperType", parms[i][^2])

  if parms[0].kind != nnkEmpty:
    parms[0] = newCall(bindSym"toWasmWrapperType", parms[0])
  wrapper.params = parms
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
    call.add(newCall("toWasm", n))

  # Copy pragmas from def to wrapper
  for pr in p[4]:
    wrapper.addPragma(pr)

  wrapper.addPragma(ident"inline")
  wrapper.addPragma(ident"enforceNoRaises")
  wrapper.addPragma(newColonExpr(ident"stackTrace", ident"off"))

  p.addPragma(ident"importc")
  p.addPragma(ident"enforceNoRaises")
  inc id
  p.addPragma(newColonExpr(ident"codegenDecl", newLit(codegenDeclStr(argSig & body))))

  wrapper.body = quote do:
    `call`

  result = quote do:
    `p`
    `wrapper`

  # echo "R: ", repr result

proc joins(a: varargs[string]): string = a.join("")

proc importWasmAux(body: string, p: NimNode, raw, expr, prop, meth: bool): NimNode =
  p.expectKind(nnkProcDef)
  var numArgs = 0
  for _, _, _, _ in p.params.arguments:
    inc numArgs

  let retType = p.params[0] or ident"void"
  var funSig: NimNode
  if raw:
    funSig = newLit(0)
  elif expr:
    funSig = newCall(bindSym"retTypeSig", retType, newLit(0), newLit(0))
  else:
    let retType = p.params[0] or ident"void"
    funSig = newCall(bindSym"retTypeSig", retType, newLit(prop), newLit(meth), newLit(numArgs))

  let typSig = newCall(bindSym"joins", newCall(bindSym"wasmTypeSig", retType))
  for _, _, typ, _ in p.params.arguments:
    typSig.add(newCall(bindSym"wasmTypeSig", typ))


  result = newCall(bindSym"importwasmAux2", newLit(body), typSig, p, funSig, newLit(numArgs))
  # echo "RR: ", repr result

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
  result = importWasmAux(n, b, false, false, true, false)

macro importwasmm*(a1: untyped, more: varargs[untyped]): untyped =
  # Import method from js to wasm
  # ```
  # proc getElementById(d: JSObj, id: cstring): JSObj {.importwasmm.} # js: return d.getElementById(id)
  # ```
  let (b, n) = parseArgs(a1, more)
  result = importWasmAux(n, b, false, false, false, true)

macro importwasmf*(a1: untyped, more: varargs[untyped]): untyped =
  # Import function from js to wasm
  # ```
  # proc alert(t: cstring) {.importwasmf.} # js: alert(t)
  # ```
  let (b, n) = parseArgs(a1, more)
  result = importWasmAux(n, b, false, false, false, false)

macro importwasmraw*(name: static[string], b: untyped): untyped =
  # Import raw chunk of js code to wasm. It's usually better
  # to use `importwasmexpr` instead.
  # ```
  # proc myfunction(t: cstring) {.importwasmraw: """
  #   var d = document;
  #   var e = d.getElementById($0);
  #   return e
  #   """.}
  # ```
  # Refer to args with `$NUM`, NUM starting from 0.
  result = importWasmAux(name, b, true, false, false, false)

macro importwasmexpr*(name: static[string], b: untyped): untyped =
  # Import raw chunk of js code to wasm, but prepend corresponding return
  # directive in front of it, if necessary.
  # ```
  # proc myfunction(t: cstring): JSRef {.importwasmexpr: """
  #   document.getElementById($0)
  #   """.}
  # ```
  # Refer to args with `$NUM`, NUM starting from 0.
  result = importWasmAux(name, b, false, true, false, false)

proc isNilJSShim(e: JSExternRef): bool {.importwasmexpr: "$0 == null".}
proc isNil*(r: JSExternRef): bool {.stackTrace: off, enforceNoRaises.} =
  {.emit: """
  #if __has_builtin(__builtin_wasm_ref_is_null_extern)
    `result` = __builtin_wasm_ref_is_null_extern(`r`);
  #else
    `result` = `isNilJSShim`(`r`);
  #endif
  """.}

template `==`*(e: JSExternRef, n: typeof(nil)): bool = isNil(e)
template `==`*(n: typeof(nil), e: JSExternRef): bool = isNil(e)

proc isNil*(j: JSRef): bool {.inline, enforceNoRaises.} = toJSExternRef(j) == nil
proc isNil*(o: JSObj): bool {.inline, enforceNoraises.} = o.o.isNil

proc uint8MemSlice(s: pointer, length: uint32): JSRef {.importwasmexpr: "new Uint8Array(_nima, $0, $1)".}

proc strToJs(m: JSRef): JSExternObj[JSString] {.importwasmf: "new TextDecoder().decode", enforceNoRaises.}

proc strToJs*(s: pointer, length: uint32): JSExternObj[JSString] {.enforceNoRaises.} =
  strToJs(uint8MemSlice(s, length))

proc strLen(s: JSExternObj[JSString]): uint32 {.importwasmp: "length".}
proc strWriteOut(s: JSExternObj[JSString], m: JSRef): uint32 {.importwasmexpr: """
new TextEncoder().encodeInto($0, $1).written
""".}

proc strToJs(s: openarray[char]): JSExternObj[JSString] {.inline, enforceNoRaises.} =
  let sz = s.len
  strToJs(cast[pointer](addr s), sz.uint32)

template toWasm*(a: string): JSExternObj[JSString] = strToJs(a)
template toWasm*(a: cstring): JSExternObj[JSString] = strToJs(cast[pointer](a), a.len.uint32)

template isNil*(o: JSExternObj): bool = isNil(JSExternRef(o))

converter toString*(j: JSExternObj[JSString]): string =
  if not JSExternRef(j).isNil:
    var sz = strLen(j)
    if sz != 0:
      sz *= 3
      result.setLen(sz)
      sz = strWriteOut(j, uint8MemSlice(addr result[0], sz))
      result.setLen(sz)

proc `$`*(j: JSExternObj[JSString]): string {.inline.} = toString(j)

converter toJSExternObj*(a: string): JSExternObj[JSString] {.enforceNoRaises.} = strToJs(a)
converter toJSExternObj*(a: cstring): JSExternObj[JSString] {.enforceNoRaises.} = strToJs(cast[pointer](a), a.len.uint32)
# converter toJSExternObj*[T, Y](a: JSExternObj[T]): JSExternObj[Y] {.enforceNoRaises.} = JSExternObj[Y](a)


proc `==`*(e: JSExternObj, n: typeof(nil)): bool {.inline, enforceNoRaises.} = isNil(e)
proc `==`*(n: typeof(nil), e: JSExternObj): bool {.inline, enforceNoRaises.} = isNil(e)


converter toJSRef*(e: JSExternRef): JSRef =
  createJSRef(e)

converter toJSExternObj*[T: JSObj](o: T): JSExternObj[T] {.inline.} =
  JSExternObj[T](wasmTableGet(globalRefs, cast[int32](o.o)))

converter toJSObj*[T: JSObj](e: JSExternObj[T]): T {.inline.} =
  T(o: cast[JSRef](storeRef(JSExternRef(e))))

proc to*[T: JSObj, F](e: JSExternObj[F]): T {.inline.} =
  T(o: cast[JSRef](storeRef(JSExternRef(e))))

proc toFuncExternRef(p: pointer): JSExternFuncRef {.importc, codegendecl: codegenDeclStr("\\06\\01_nimm.exports.__indirect_function_table.get").}

proc argNameForIdx(i: int): string =
  # generate a stable short arg name, unique for i
  # Returns "a" for 0, "b" for 1, and so on...
  const alphabetSize = ord('z') - ord('a')
  if i < alphabetSize:
    return $(char(ord('a') + i))
  elif i < alphabetSize * 2:
    return $(char(ord('A') + i - alphabetSize))
  else:
    doAssert(false, "too many args is not implemented")

var closurizeId {.compileTime.} = 0
macro closurizeFunction(p: typed, funcPtr, env: typed): untyped =
  let t = getTypeInst(p)
  var argcount = 0
  for a in arguments(t.params):
    inc argCount
  
  var decl = ""
  if argCount == 1:
    decl &= argNameForIdx(0)
  else:
    decl &= "("
    for i in 0 ..< argCount:
      if i != 0:
        decl &= ","
      decl &= argNameForIdx(i)
    decl &= ")"
  decl &= "=>$$0("
  for i in 0 ..< argCount:
    if i != 0:
      decl &= ","
    decl &= argNameForIdx(i)
  if argCount > 0:
    decl &= ","
  decl &= "$$1)"
  
  let prcId = ident("wasmrtClosurize" & $closurizeId)
  inc closurizeId
  let codeDecl = codegenDeclStr("\\02\\02" & decl)
  let s = genSym(nskProc, "closurize")
  result = quote do:
    proc `prcId`(p: JSExternFuncRef, e: pointer): JSExternRef {.importc, codegenDecl: `codeDecl`.}
    `prcId`(`funcPtr`, `env`)

proc identity(p: JSExternFuncRef): JSExternRef {.importc, codegenDecl: codegenDeclStr("\\02\\01$$0").}
proc toClosureFuncExternRef(p: proc{.closure.}): JSExternRef =
  # defineClosurizeFunction(p)
  let rp = rawProc(p)
  if rp == nil:
    nullExternRef()
  else:
    let ep = toFuncExternRef(rp)
    let e = rawEnv(p)
    if e == nil:
      identity(ep)
    else:
      closurizeFunction(p, ep, e)

template toWasm*(p: proc{.cdecl.}): JSExternFuncRef = toFuncExternRef(cast[pointer](p))
template toWasm*(p: proc{.closure.}): JSExternRef = toClosureFuncExternRef(p)
template toWasm*(a: JSString): JSExternObj[JSString] = JSExternObj[JSString](toJSExternRef(a.o))

proc retain*(r: JSRef) =
  let idx = cast[int32](r)
  inc refs[idx]

proc release*(r: JSRef) {.noinline.} =
  let idx = cast[int32](r)
  var cnt = refs[idx]
  dec cnt
  if cnt == 0:
    refs[idx] = firstRef
    firstRef = idx
    wasmTableSet(globalRefs, idx, nullExternRef())
  else:
    refs[idx] = cnt

proc delete*(r: JSRef) =
  release(r)

proc `=copy`*(a: var JSObj, b: JSObj) =
  retain(b.o)
  release(a.o)
  a.o = b.o

proc `=destroy`*(a: var JSObj) =
  release(a.o)
  a.o = JSRef(nil)

converter toJSExternRef*(e: JSObj): JSExternRef {.inline.} = toJSExternRef(e.o)

converter toJSObj*(e: JSExternRef): JSObj =
  if e.isNil: return JSObj()
  JSObj(o: createJSRef(e))

when not defined(release):
  proc nimerr() {.exportwasm.} =
    writeStackTrace()
    raise newException(Exception, "")

proc to*(o: sink JSObj, T: typedesc[JSObj]): T {.inline.} =
  let r = o.o
  wasMoved(o)
  T(o: r)

template to*[From](o: JSExternObj[From], T: typedesc[JSObj]): auto = JSExternObj[T](o)

const initCode = (""";
var W = WebAssembly, o = {}, g = globalThis, q='';
for (i of W.Module.imports(m)) {
  var n = i.name,
    c = a => n.charCodeAt(a);

  if (c(0) == 94) { // First char equals '^'
    var
    r = c(1), // Fun sig
    a = q,
    F = r & 1, // Prepend first arg
    p = c(2), // Number of arguments
    b = n.substring(3); // Source code of the function

    for (I=0; I<p; ++I) a+= '$' + I + ',';

    if (r & 4) { // have arguments
      b += '(';
      for (I = F; I < p; ++I)
        b += '$' + I + ',';
      b += ')'
    }

    // console.log("BODY",
      // (r&2?'return ':q) + // Prepend return
      // (F?'$0.':q) + // Prepend first arg dot
      // b + // The source code
      // (r&8?'=$' + (p-1):q) // Append assignment to last arg
    // );



    o[n] = new Function(a,
      (r&2?'return ':q) + // Prepend return
      (F?'$0.':q) + // Prepend first arg dot
      b + // The source code
      (r&8?'=$' + (p-1):q) // Append assignment to last arg
    )
  }
  else
    console.warn('Undefined external symbol: ', n),
""" & (if not defined(release): """o[n] = new Function(q, 'console.error("Undefined symbol called: ' + n + '"); _nime.nimerr()')"""
      else: "o[n] = new Function(q, `throw new Error('Undefined symbol called: ${n}')`)") &
"""
}

g._nimc = q;

g._nimmu = () => g._nima = q.buffer;

W.instantiate(m, {""" & wasmrtImportModuleName & """: o}).then(m => {
  g._nimm = m;
  n = g._nime = m.exports;
  q = n.memory;
  _nimmu();
  for(i in n) if (i[0]==';') n[i]()
})
""").minifyJs().escapeJs()

{.emit: ["""
void __nimWasmInit() __attribute__((export_name(""" & '"' & initCode & """"))) {
  void NimMain();
  NimMain();
}
"""].}

proc consoleWarn(a: JSString) {.importwasmf: "console.warn".}

proc isNodejsAux(): bool {.importwasmp: "typeof process!='undefined'".}
proc isNodejs(): bool {.enforceNoRaises.} =
  when defined(wasmrtOnlyBrowser):
    false
  elif defined(wasmrtOnlyNode):
    true
  else:
    isNodejsAux()

proc nodejsWriteToStream(s: int32, byteArray: JSRef) {.importwasmraw:"process[$0?'stderr':'stdout'].write($1)".}

proc consoleAppend(s: JSString) {.importwasmraw: "_nimc += $0".}
proc consoleFlush(s: int32) {.importwasmraw: "console[$0?'error':'log'](_nimc); _nimc = ''".}

proc fwriteImpl(p: pointer, sz, nmemb: csize_t, stream: pointer): csize_t {.enforceNoRaises.} =
  if cast[int32](stream) in {0, 1}:
    # stdout
    let fzs = uint32(sz * nmemb)
    if isNodejs():
      nodejsWriteToStream(cast[int32](stream), uint8MemSlice(p, fzs))
    else:
      consoleAppend(strToJs(p, fzs))
    return nmemb
  else:
    consoleWarn("fwrite wrong stream")

proc fwrite(p: pointer, sz, nmemb: csize_t, stream: pointer): csize_t {.exportc.} =
  fwriteImpl(p, sz, nmemb, stream)

proc flockfile(f: pointer) {.exportc.} = discard
proc funlockfile(f: pointer) {.exportc.} = discard
proc ferror(f: pointer): cint {.exportc.} = discard

proc exit(code: cint) {.exportc.} =
  when not defined(release):
    consoleWarn "exit called, ignoring"

proc fflush(stream: pointer): cint {.exportc.} =
  if cast[int32](stream) in {0, 1} and not isNodejs():
    consoleFlush(cast[int32](stream))

proc fputc(c: cint, stream: pointer): cint {.exportc.} =
  var buf = cast[uint8](c)
  if fwriteImpl(addr buf, sizeof(buf).csize_t, 1, stream) == 1:
    c
  else:
    -1

proc munmap(a: pointer, len: csize_t): cint {.exportc.} =
  when not defined(release):
    consoleWarn "munmap called, ignoring"

proc dlopen(a: cstring, f: cint): cint {.exportc.} =
  when defined(release):
    exit(-1)
  else:
    consoleWarn("dlopen called for:")
    consoleWarn(a)
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

proc wasmAlloc(block_size: uint): pointer {.inline, enforceNoRaises.} =
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

proc mmap(a: pointer, len: csize_t, prot, flags, fildes: cint, off: int64): pointer {.exportc.} =
  if unlikely a != nil:
    when not defined(release):
      consoleWarn("mmap called with wrong arguments")
    return nil

  wasmAlloc(len)

proc malloc(sz: csize_t): pointer {.exportc.} = alloc(sz)
proc free(p: pointer) {.exportc.} = dealloc(p)

# proc strtodimpl(p: cstring): cdouble {.importwasmf: "parseFloat".}
# proc strtod(p: cstring): cdouble {.exportc, stackTrace: off.} = strtodimpl(p)

# Suppress __wasm_call_ctors
# https://stackoverflow.com/questions/72568387/why-is-an-objects-constructor-being-called-in-every-exported-wasm-function
proc initialize() {.stackTrace: off, exportc: "_initialize".} =
  proc ctors() {.importc: "__wasm_call_ctors".}
  ctors()

when compileOption("stackTrace"):
  {.push stackTrace: off.}
  proc wasmStackTrace() {.exportwasm.} =
    writeStackTrace()
  {.pop.}

when not defined(gcDestructors):
  GC_disable()

import wasmrt/[libc, printf]
import std/compilesettings

# This is required to export function table __indirect_function_table.
{.passL:"-Wl,--export-table".}

# Compiler and linker options
static:
  # Nim will pass -lm and -lrt to linker, so we provide stubs, by compiling empty c file into nimcache/lib*.a, and pointing
  # the linker to nimcache
  const nimcache = querySetting(nimcacheDir)
  {.passL: "-L" & nimcache.}
  var compilerPath = querySetting(ccompilerPath)
  if compilerPath == "":
    compilerPath = "clang"
  else:
    compilerPath &= "/clang"

  when defined(windows):
    discard staticExec("mkdir " & nimcache)
  else:
    discard staticExec("mkdir -p " & nimcache)
  let (o1, r1) = gorgeEx(compilerPath & " -c --target=wasm32-unknown-unknown-wasm -o " & nimcache & "/libm.a -x c -", input = "\n")
  if r1 != 0:
    echo "Error compiling libm stub:"
    echo o1
    doAssert(false)
  let (o2, r2) = gorgeEx(compilerPath & " -c --target=wasm32-unknown-unknown-wasm -o " & nimcache & "/librt.a -x c -", input = "\n")
  if r2 != 0:
    echo "Error compiling librt stub:"
    echo o2
    doAssert(false)

when not defined(wasmrtOverrideLibcIncludes):
  const muslLibcPath = currentSourcePath().replace("\\", "/").parentDir() / "wasmrt/musl-libc/"
  {.passC: "-I" & muslLibcPath & "wasmrt".}
  {.passC: "-I" & muslLibcPath & "arch/generic".}
  {.passC: "-I" & muslLibcPath & "include".}
