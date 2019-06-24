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
# --nocppexceptions

# let llBin = getEnv("WASM_LLVM_BIN")
# if llBin.len == 0:
#   raise newException(Exception, "WASM_LLVM_BIN env var should be set to directory path where clang/clang++ executables are")

# var llLinkerBin = getEnv("WASM_LLVM_LD_BIN")
# if llLinkerBin.len == 0:
#   llLinkerBin = llBin


let llTarget = "wasm32-unknown-unknown-wasm"

switch("passC", "--target=" & llTarget)
switch("passL", "--target=" & llTarget)

switch("passC", "-mexception-handling")
switch("passC", "-I/usr/include/c++/8.2.1 -I/usr/include/c++/8.2.1/x86_64-pc-linux-gnu/32")

# switch("passC", "-nostdlib")
# switch("passC", "-ffreestanding")
# switch("passL", "-ffreestanding")
# switch("passC", "-fno-builtin-")

# switch("clang.cpp.exe", llBin & "/clang++")
# switch("clang.exe", llBin & "/clang")
# switch("clang.linkerexe", llLinkerBin & "/clang")
# switch("clang.cpp.linkerexe", llLinkerBin & "/clang")

var linkerOptions = "-nostdlib -Wl,--no-entry,--allow-undefined,--export-dynamic"
# linkerOptions &= ",--gc-sections,--strip-all" # gc-sections seems to not have any effect

switch("clang.options.linker", linkerOptions)
switch("clang.cpp.options.linker", linkerOptions)
