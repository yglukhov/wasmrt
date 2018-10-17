# Package

version       = "0.1.0"
author        = "Yuriy Glukhov"
description   = "Nim wasm runtime"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.1"

proc buildExample(name: string) =
  exec "nim c --out:" & name & ".wasm tests/" & name
  exec "wasm-gc " & name & ".wasm"
  exec "wasm2wat -o " & name & ".wast " & name & ".wasm"
  exec "node --experimental-wasm-eh ./nodetest.js"

task test, "Test":
    buildExample("test")
