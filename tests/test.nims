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
  raise newException(Exception, "WASM_LLVM_BIN env var should be set to directory path where clang/clang++ executables are")

let llTarget = "wasm32-unknown-unknown-wasm"

switch("passC", "--target=" & llTarget)
switch("passL", "--target=" & llTarget)

switch("passC", "-mexception-handling")

switch("passC", "-nostdlib")
# switch("passC", "-ffreestanding")
# switch("passL", "-ffreestanding")
# switch("passC", "-fno-builtin-")

switch("clang.cpp.exe", llBin & "/clang++")
switch("clang.exe", llBin & "/clang")
switch("clang.linkerexe", llBin & "/clang")
switch("clang.cpp.linkerexe", llBin & "/clang")

var linkerOptions = "-nostdlib -Wl,--no-entry,--allow-undefined"
linkerOptions &= ",--gc-sections,--strip-all" # gc-sections seems to not have any effect

switch("clang.options.linker", linkerOptions)
switch("clang.cpp.options.linker", linkerOptions)
