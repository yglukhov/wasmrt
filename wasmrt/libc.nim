import posix, strutils, os

import ../wasmrt

const
  builtinsPath = currentSourcePath.rsplit({DirSep, AltSep}, 1)[0] &
    "/llvm-builtins/builtins/"

template c(s: string) =
  {.compile: builtinsPath & s.}

# TODO: Extend the following list as needed
c "multi3.c"
c "lshrti3.c"
c "ashrti3.c"

proc gettimeImpl(): cint {.importwasmf: "Date.now".}

proc clock_gettime(clkId: Clockid, tp: var Timespec): cint {.exportc.} =
  let t = gettimeImpl()
  tp.tv_sec = Time(t div 1000)
  tp.tv_nsec = (t mod 1000) * 1000
