import jsbind

proc consoleLog*(s: cstring) {.jsimportgWithName: "console.log".}

consoleLog("HEllo with jsbind")
