import ../wasmrt

block:
  proc a(): int32 {.importwasmraw: "return 123".}
  doAssert(a() == 123)
block:
  proc a(): string {.importwasmraw: "return 'hello world'".}
  doAssert(a() == "hello world")
block:
  proc a(): string {.importwasmexpr: "'hello world'".}
  doAssert(a() == "hello world")
block:
  proc a(s: string): string {.importwasmexpr: "$0 + ' world'".}
  doAssert(a("hello") == "hello world")
block:
  proc plus(a: int, b: string): int {.importwasmexpr: "$0 + parseInt($1)".}
  doAssert(plus(3, "2") == 5)
block:
  proc init() {.importwasmraw: """
  globalThis.myJSFunction = () => "hello!";
  """.}
  init()
  proc myJSFunction(): string {.importwasmf.}
  proc myJSFunctionAnotherWay(): JSString {.importwasmf: "myJSFunction".}
  doAssert(myJSFunction() == "hello!")
  doAssert(myJSFunctionAnotherWay() == "hello!")
block:
  proc init() {.importwasmraw: """
  globalThis.myJSFunction = (a, b) => a + b;
  """.}
  init()
  proc myJSFunction(a, b: int): int {.importwasmf.}
  doAssert(myJSFunction(2, 3) == 5)
  proc myJSFunction(a, b: float): float {.importwasmf.}
  doAssert(myJSFunction(2.0, 3.0) == 5.0)
  proc myJSFunction(a, b: string): string {.importwasmf.}
  doAssert(myJSFunction("2", "3") == "23")
  proc myJSFunction(a, b: JSString): string {.importwasmf, used.}
  doAssert(myJSFunction("1", "2") == "12")
block:
  proc myJSFunction(a, b: JSString): JSString {.importwasmf.}
  doAssert(myJSFunction("5", "6") == "56")
  proc myJSFunctionC(a, b: cstring): JSString {.importwasmf: "myJSFunction".}
  doAssert(myJSFunctionC("5", "6") == "56")
block:
  proc init() {.importwasmraw: """
  globalThis.myJSObject = {
    someFunc: (a, b) => a + b,
    someProp: "hello"
  };
  """.}
  init()
  proc myJSObject(): JSObj {.importwasmp.}
  proc someProp(o: JSObj): JSString {.importwasmp.}
  proc somePropButObj(o: JSObj): JSObj {.importwasmp: "someProp".}
  proc `someProp=`(o: JSObj, s: JSString) {.importwasmp.}
  proc someFunc(o: JSObj, a, b: int): int {.importwasmm.}
  doAssert(myJSObject().someProp() == "hello")
  doAssert(myJSObject().somePropButObj().to(JSString) == "hello")
  doAssert(myJSObject().someFunc(1, 2) == 3)
  myJSObject().someProp = "hi"
  doAssert(myJSObject().someProp == "hi")

  proc foo() =
    let j = myJSObject()
    doAssert(j.someProp == "hi")
    let jo: JSObj = myJSObject()
    doAssert(jo.someProp == "hi")
  foo()

block:
  proc getNull(): JSObj {.importwasmexpr: "null".}
  doAssert(getNull() == nil)
  doAssert(nil == getNull())
  var j: JSObj = getNull()
  doAssert(j.isNil)


block: # Callback
  proc setCallbackAux(t: int, c: proc(a: int) {.cdecl.}) {.importwasmraw: """
  $1($0 + 123)
  """.}

  var a1 = 0
  var a2 = 0
  proc onCallback1(b: int) {.cdecl.} =
    a1 = b
  proc onCallback2(b: int) {.cdecl.} =
    a2 = b

  proc setCallback() =
    setCallbackAux(10, onCallback1)
    setCallbackAux(20, onCallback2)

  setCallback()
  doAssert(a1 == 133)
  doAssert(a2 == 143)

block: # Callback
  proc setCallbackAux(t: int, c: proc(a: int, p: pointer) {.cdecl.}, p: pointer) {.importwasmraw: """
  $1($0 + 123, $2)
  """.}

  type
    Wrapper = ref object
      p: proc(a: int)

  proc onCallback(a: int, p: pointer) {.cdecl.} =
    let w = cast[Wrapper](p)
    w.p(a)
    GC_unref(w)

  proc setCallback(ms: int, cb: proc(a: int)) =
    let w = Wrapper(p: cb)
    GC_ref(w)
    setCallbackAux(ms, onCallback, cast[pointer](w))

  var a = 0
  setCallback(10) do(b: int):
    a = b
  doAssert(a == 133)

block: # Callback
  proc setCallback(t: int, c: proc(a: int)) {.importwasmraw: """
  $1($0 + 123)
  """.}

  proc main() =
    var a = 12
    var cb = proc(b: int) =
      a = b + 1

    setCallback(5, cb)
    doAssert(a == 123 + 5 + 1)

  main()

block: # Callback with string
  proc setCallback(t: int, c: proc(a0: int, s: JSExternObj[JSString])) {.importwasmraw: """
  $1(1, "hello world")
  """.}

  proc setCallback(c: proc(s: JSExternRef)) {.importwasmraw: """
  $0("hello world")
  """.}

  proc main() =
    var a = ""
    var cb = proc(a0: int, s: JSExternObj[JSString]) =
      a = s

    setCallback(5, cb)
    doAssert(a == "hello world")
    a = ""

    let anotherCb = proc(s: JSExternRef) =
      a = s.to(JSString)

    setCallback(anotherCb)
    doAssert(a == "hello world")

  main()

block: # Callback with nil env
  proc setCallback(t: int, c: proc(a, b: int)) {.importwasmraw: """
  $1($0 + 123, 16)
  """.}

  var called = 0

  proc main() =
    var cb = proc(a, b: int) =
      doAssert(a == 123 + 6)
      doAssert(b == 16)
      called = b

    setCallback(6, cb)
    doAssert(called == 16)

  main()

block:
  # Custom types
  type
    HTMLElement = object of JSObj
    Canvas = object of HTMLElement
  proc objType(e: HTMLElement): string {.importwasmp.}
  proc getSomeCanvas(): Canvas {.importwasmexpr: "{objType:'canvas'}".}
  proc getSomeElement(): HTMLElement {.importwasmexpr: "{objType:'element'}".}
  proc append(e, c: HTMLElement) {.importwasmraw: "$0.appended = $1".}
  proc appended(e: HTMLElement): HTMLElement {.importwasmp.}

  proc test() =
    let a = getSomeElement()
    doAssert(a.objType == "element")
    let c = getSomeCanvas()
    doAssert(c.objType == "canvas")
    a.append(c)
    doAssert(a.appended.objType == "canvas")
    let ao: HTMLElement = getSomeElement()
    doAssert(ao.objType == "element")
    let co: Canvas = getSomeCanvas()
    doAssert(co.objType == "canvas")
    ao.append(co)
    doAssert(ao.appended.objType == "canvas")
    let ce: HTMLElement = getSomeCanvas().toJSObj()
    a.append(ce)
    doAssert(a.appended.objType == "canvas")
    let ce1 = c.to(HTMLElement)
    a.append(ce1)
    doAssert(a.appended.objType == "canvas")
  test()

block:
  proc test() =
    var v: JSExternObj[JSObj]
    var s: JSExternObj[JSString]
    v = s
  test()

block:
  proc test() =
    proc someObj(): JSObj {.importwasmexpr:"'hi'".}
    let o = someObj().toJSObj()
    let o1 = someObj().toJSObj()
    var emptyObj: JSObj
    doAssert(o != emptyObj)
    doAssert(cast[int](o.o) != cast[int](o1.o))
    doAssert(o == o1)
  test()


echo "ok"
