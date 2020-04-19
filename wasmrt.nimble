# Package

version       = "0.1.0"
author        = "Yuriy Glukhov"
description   = "Nim wasm runtime"
license       = "MIT"

# Dependencies

requires "nim >= 1.2"

import os, oswalkdir

proc buildExample(name: string, shouldFail = false) =
  echo "Running test ", name, (if shouldFail: " [should fail]" else: "")
  exec "nim c --out:" & name & ".wasm tests/" & name
  exec "wasm-gc " & name & ".wasm"
  exec "wasm2wat -o " & name & ".wast " & name & ".wasm"
  if shouldFail:
    var failed = false
    try:
      exec "node ./tests/runwasm.js " & name & ".wasm"
    except:
      failed = true
    assert(failed, "Test " & name & " should fail but did not")
  else:
    exec "node ./tests/runwasm.js " & name & ".wasm"

task test, "Test":
  for f in oswalkdir.walkDir("tests"):
    # Compile all nim modules, except those starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".nim":
      if sf.name.startsWith("t_"):
        buildExample(sf.name)
      elif sf.name.startsWith("f_"):
        buildExample(sf.name, shouldFail = true)
