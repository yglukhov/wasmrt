import posix

import ../wasmrt

proc gettimeImpl(): cint {.importwasm: """
return Date.now()
""".}

proc clock_gettime(clkId: Clockid, tp: var Timespec): cint {.exportc.} =
  let t = gettimeImpl()
  tp.tv_sec = Time(t div 1000)
  tp.tv_nsec = (t mod 1000) * 1000
