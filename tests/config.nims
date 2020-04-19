--os:linux
--cpu:i386
--cc:clang
# --gc:arc # This is set in the nimble test task
--d:release
--nomain
--opt:size
--listCmd
--d:wasm
--stackTrace:off
--d:noSignalHandler
--exceptions:goto
--app:lib

let llTarget = "wasm32-unknown-unknown-wasm"

switch("passC", "--target=" & llTarget)
switch("passL", "--target=" & llTarget)

switch("passC", "-I/usr/include") # Wouldn't compile without this :(

switch("passC", "-flto") # Important for code size!

# gc-sections seems to not have any effect
var linkerOptions = "-nostdlib -Wl,--no-entry,--allow-undefined,--export-dynamic"
linkerOptions &= ",--gc-sections,--strip-all"

switch("clang.options.linker", linkerOptions)
switch("clang.cpp.options.linker", linkerOptions)
