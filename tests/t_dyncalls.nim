import ../wasmrt

proc setTimeoutAux(t: int, c: proc(p: pointer) {.cdecl.}, p: pointer) {.importwasmraw: """
setTimeout(() => _nime._dvi($1, $2), $0)
""".}

type
  Wrapper = ref object
    p: proc()

proc onTimeout(p: pointer) {.cdecl.} =
  let w = cast[Wrapper](p)
  w.p()
  GC_unref(w)

proc setTimeout(ms: int, cb: proc()) =
  defineDyncall("vi")
  let w = Wrapper(p: cb)
  GC_ref(w)
  setTimeoutAux(ms, onTimeout, cast[pointer](w))

setTimeout(10) do():
  echo "callback called"
