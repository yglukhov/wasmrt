import base64
import zippy

const runNimWasm = "w=>{for(i of WebAssembly.Module.exports(w)){n=i.name;if(n[0]==';'){new Function('m',n)(w);break}}}"

proc wasmToHtml*(wasmData: string): string =
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

when isMainModule:
  import os
  proc main() =
    let c = readFile(paramStr(1))
    var s = ""
    for f in [wasmToHtml, wasmToHtml2, wasmToHtml3]:
      let ns = f(c)
      if s.len == 0 or ns.len < s.len:
        s = ns
    writeFile(paramStr(2), s)
  main()
