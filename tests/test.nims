# --os:standalone
--cpu:i386
--cc:clang
# --gc:none
--d:release
--nomain
--opt:size
--listCmd
--d:wasm
--stackTrace:off
--d:noSignalHandler
--d:nimNoLibc

let llBin = getEnv("WASM_LLVM_BIN")
if llBin.len == 0:
  raise newException(Exception, "WASM_LLVM_BIN env var is not set")

let llTarget = "wasm32-unknown-unknown-wasm"

switch("passC", "--target=" & llTarget)
switch("passL", "--target=" & llTarget)

switch("passC", "-mexception-handling")

switch("passC", "-nostdlib")
# switch("passC", "-ffreestanding")
# switch("passL", "-ffreestanding")
# switch("passC", "-fno-builtin-")

# switch("passC", "-I/usr/local/Cellar/emscripten/HEAD-f6d775c/libexec/system/include/libc")
# switch("passC", "-I/usr/local/Cellar/emscripten/HEAD-f6d775c/libexec/system/include/libcxx")


switch("clang.cpp.exe", llBin & "/clang++")
switch("clang.exe", llBin & "/clang")
switch("clang.linkerexe", llBin & "/clang")
switch("clang.cpp.linkerexe", llBin & "/clang")

# let linkerOptions = "-nostdlib -Wl,--no-entry,--allow-undefined,--gc-sections,--strip-all"
var linkerOptions = "-nostdlib -Wl,--no-entry,--allow-undefined"
linkerOptions &= ",--strip-all"

switch("clang.options.linker", linkerOptions)
switch("clang.cpp.options.linker", linkerOptions)
