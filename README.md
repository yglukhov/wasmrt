# wasmrt [![CI](https://github.com/yglukhov/wasmrt/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/yglukhov/wasmrt/actions?query=branch%3Amaster) [![nimble](https://img.shields.io/badge/nimble-black?logo=nim&style=flat&labelColor=171921&color=%23f3d400)](https://nimble.directory/pkg/wasmrt)

Compile nim to wasm
```nim
import wasmrt
proc consoleLog(a: cstring) {.importwasmraw: "console.log(_nimsj($0))".}
consoleLog("Hello, world!")
```

```sh
nim c --out:test.wasm test.nim # Special nim config is required, see below
node tests/runwasm.js test.wasm
```

# Prerequisites
- clang 8.0 or later
- Special Nim config, like [this one](https://github.com/yglukhov/wasmrt/blob/master/tests/config.nims)
- [Optional] [wasm-opt](https://github.com/WebAssembly/binaryen) - a tool to compact your wasm file

# Run your wasm
The wasm file generated this way is pretty standalone, and requires only the following JavaScript code to bootstrap:
```js
function runNimWasm(w){for(i of WebAssembly.Module.exports(w)){n=i.name;if(n[0]==';'){new Function('m',n)(w);break}}}
```
`runNimWasm` takes the output of `WebAssembly.compile` function. E.g. to run a wasm file in nodejs, use smth like [runwasm.js](https://github.com/yglukhov/wasmrt/blob/master/tests/runwasm.js)

# Convert wasm to html
The generated wasm file can be "converted" to a standalone html file with `wasm2html` tool provided in this package.
```sh
nim c --out:test.wasm test.nim # Special nim config is required, see below
wasm2html test.wasm test.html
```

# Why no Emscripten?
The goal of this project is to produce self-contained standalone wasm files from nim code, without any JS glue, or "desktop platform emulation".
