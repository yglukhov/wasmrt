import base64
import zippy

const runNimWasm = "w=>{for(i of WebAssembly.Module.exports(w)){n=i.name;if(n[0]==';'){new Function('m',n)(w);break}}}"

proc wasmToHtml1*(wasmData: string): string =
  """<!DOCTYPE html>
<html><head><script>
WebAssembly.compileStreaming(fetch('data:application/wasm;base64,""" & base64.encode(wasmData) & """')).then(""" & runNimWasm & """)
</script></head></html>"""

proc wasmToHtml2*(wasmData: string): string =
  let compressed = zippy.compress(wasmData, level = BestCompression, dataFormat = dfGzip)
  """<!DOCTYPE html>
<html><head><script>
fetch('data:image/png;base64,""" & base64.encode(compressed) & """').then(r=>new Response(r.body.pipeThrough(new DecompressionStream('gzip'))).arrayBuffer()).then(WebAssembly.compile).then(""" & runNimWasm & """)
</script></head></html>"""

proc wasmToHtml3*(wasmData: string): string =
  let compressed = zippy.compress(wasmData, level = BestCompression, dataFormat = dfDeflate)
  """<!DOCTYPE html>
<html><head><script>
fetch('data:image/png;base64,""" & base64.encode(compressed) & """').then(r=>new Response(r.body.pipeThrough(new DecompressionStream('deflate-raw'))).arrayBuffer()).then(WebAssembly.compile).then(""" & runNimWasm & """)
</script></head></html>"""

proc wasmToHtml*(wasmData: string): string =
  for f in [wasmToHtml1, wasmToHtml2, wasmToHtml3]:
    let ns = f(wasmData)
    if result.len == 0 or ns.len < result.len:
      result = ns

when isMainModule:
  import os
  proc main() =
    let wasm = readFile(paramStr(1))
    let html = wasmToHtml(wasm)
    writeFile(paramStr(2), html)
  main()
