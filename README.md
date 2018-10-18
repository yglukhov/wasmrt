# wasmrt [![Build Status](https://travis-ci.org/yglukhov/nimwasmrt.svg?branch=master)](https://travis-ci.org/yglukhov/nimwasmrt)

Disclaimer. This is a proof of concept, so use it carefully.

Compile nim to wasm
```nim
import wasmrt
proc consoleLog(a: cstring) {.importwasm: "console.log(_nimsj($0))".}
consoleLog("Hello, world!")
```

```sh
nim c --out:test.wasm test.nim # Special nim config is required, see below
node tests/runwasm.js test.wasm
```

# Prerequisites
- clang with WebAssembly support. You can build it yourself:
```
tag=release_70
INSTALL_PREFIX=$(pwd)/llvm-wasm
git clone --depth 1 --branch $tag https://github.com/llvm-mirror/llvm.git
cd llvm/tools
git clone --depth 1 --branch $tag https://github.com/llvm-mirror/clang
git clone --depth 1 --branch $tag https://github.com/llvm-mirror/lld
cd ..
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DLLVM_TARGETS_TO_BUILD= -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly ..
make -j 4 install
```
- Special Nim config, like [this one](https://github.com/yglukhov/nimwasmrt/blob/master/tests/test.nims)
- [Optional] [wasm-gc](https://github.com/alexcrichton/wasm-gc) - a tool to compact your wasm file

# Run your wasm
The wasm file generated this way is pretty standalone, and requires only the following JavaScript code to bootstrap:
```js
function runNimWasm(w){for(i of WebAssembly.Module.exports(w)){n=i.name;if(n[0]==';'){new Function('m',n)(w);break}}}
```
`runNimWasm` takes the output of `WebAssembly.compile` function. E.g. to run a wasm file in nodejs, use smth like [runwasm.js](https://github.com/yglukhov/nimwasmrt/blob/master/tests/runwasm.js)

# Caveats
- Exceptions don't work.
- Nim GC is disabled on start, you have to run it carefully close to the stack bottom, otherwise it can collect live references.
