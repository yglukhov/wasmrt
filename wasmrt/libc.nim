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
  tp.tv_nsec = (t mod 1000) * 1000000

proc atan2Aux(a, b: float): float {.importwasmf: "Math.atan2".}
proc atan2(a, b: cdouble): cdouble {.exportc.} = atan2Aux(a, b)
proc atan2f(a, b: cfloat): cfloat {.exportc.} = atan2Aux(a, b)

proc cosAux(a: float): float {.importwasmf: "Math.cos".}
proc cos(a: cdouble): cdouble {.exportc.} = cosAux(a)
proc cosf(a: cfloat): cfloat {.exportc.} = cosAux(a)

proc sinAux(a: float): float {.importwasmf: "Math.sin".}
proc sin(a: cdouble): cdouble {.exportc.} = sinAux(a)
proc sinf(a: cfloat): cfloat {.exportc.} = sinAux(a)

proc powAux(a, b: float): float {.importwasmf: "Math.pow".}
proc pow(a, b: cdouble): cdouble {.exportc.} = powAux(a, b)
proc powf(a, b: cfloat): cfloat {.exportc.} = powAux(a, b)
