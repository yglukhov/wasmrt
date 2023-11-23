# Package

version       = "0.1.0"
author        = "Yuriy Glukhov"
description   = "Nim wasm runtime"
license       = "MIT"
bin           = @["wasmrt/wasm2html"]

# Dependencies
requires "zippy" # For wasm2html

import os, oswalkdir

proc buildExample(name: string, shouldFail = false) =
  echo "Running test ", name, (if shouldFail: " [should fail]" else: "")
  exec "nim c --out:tests/" & name & ".wasm tests/" & name
  # exec "wasm-gc tests/" & name & ".wasm"
  # exec "wasm2wat -o tests/" & name & ".wast tests/" & name & ".wasm"
  if shouldFail:
    var failed = false
    try:
      exec "node ./tests/runwasm.js ./tests/" & name & ".wasm"
    except:
      echo "Test failed as it should"
      failed = true
    assert(failed, "Test " & name & " should fail but did not")
  else:
    exec "node ./tests/runwasm.js tests/" & name & ".wasm"

task test, "Test":
  for f in oswalkdir.walkDir("tests"):
    # Compile all nim modules, except those starting with "t"
    let sf = f.path.splitFile()
    if sf.ext == ".nim":
      if sf.name.startsWith("t_"):
        buildExample(sf.name)
      elif sf.name.startsWith("f_"):
        buildExample(sf.name, shouldFail = true)
