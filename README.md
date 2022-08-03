# wasmrt [![Build Status](https://github.com/yglukhov/wasmrt/workflows/CI/badge.svg?branch=master)](https://github.com/yglukhov/wasmrt/actions?query=branch%3Amaster)

Disclaimer. This is a proof of concept, use with caution.

Compile nim to wasm
```nim
import wasmrt
proc consoleLog(a: cstring) {.importwasm: "console.log(_nimsj(a))".}
consoleLog("Hello, world!")
```

```sh
nim c --out:test.wasm test.nim # Special nim config is required, see below
node tests/runwasm.js test.wasm
```

# Prerequisites
- clang 8.0 or later
- Special Nim config, like [this one](https://github.com/yglukhov/wasmrt/blob/master/tests/config.nims)
- [Optional] [wasm-gc](https://github.com/alexcrichton/wasm-gc) - a tool to compact your wasm file

# Run your wasm
The wasm file generated this way is pretty standalone, and requires only the following JavaScript code to bootstrap:
```js
function runNimWasm(w){for(i of WebAssembly.Module.exports(w)){n=i.name;if(n[0]==';'){new Function('m',n)(w);break}}}
```
`runNimWasm` takes the output of `WebAssembly.compile` function. E.g. to run a wasm file in nodejs, use smth like [runwasm.js](https://github.com/yglukhov/wasmrt/blob/master/tests/runwasm.js)

# Caveats
- Exceptions work with `--exceptions:goto`.
- Orc GC should work. But default GC should be disabled on start, and should be run carefully close to the stack bottom, otherwise it can collect live references.

# Why no Emscripten?
The goal of this project is to produce self-contained standalone wasm files from nim code, without any JS glue, or "desktop platform emulation".
