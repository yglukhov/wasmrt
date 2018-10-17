import ../wasmrt


proc consoleLog(a: cstring) {.importwasm: "console.log(_nimsj($0))".}
var s = "Hello World"
consoleLog(s & "!!!11")

