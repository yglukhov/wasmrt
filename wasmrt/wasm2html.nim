import base64

proc wasmToHtml*(wasmData: string): string =
  const runNimWasm = "w=>{for(i of WebAssembly.Module.exports(w)){n=i.name;if(n[0]==';'){new Function('m',n)(w);break}}}"
  """<html><head><script>
WebAssembly.compile(Uint8Array.from(atob('""" & base64.encode(wasmData) & """'), c => c.charCodeAt(0)).buffer).then(""" & runNimWasm & """)
</script></head></html>"""

when isMainModule:
  import os
  let c = readFile(paramStr(1))
  writeFile(paramStr(2), wasmToHtml(c))
