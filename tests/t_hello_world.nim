import ../wasmrt


proc consoleLog(a: cstring) {.importwasm: "console.log(_nimsj(a))".}
var s = "Hello World"
consoleLog(s & "!!!11")
var a = 5
echo "hi", a


import sets
var foo = initHashSet[string]()
foo.incl("hi")
foo.incl("bye")
echo "bye in s: ", "bye" in foo
echo "hello in s: ", "hello" in foo

doAssert("bye" in foo and "hello" notin foo)
