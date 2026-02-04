import ../wasmrt

{.push stackTrace:off.}

proc uint8MemSlice(s: pointer, length: uint32): JSObject {.importwasmexpr: "new Uint8Array(_nima, $0, $1)".}
proc float32MemSlice(s: pointer, length: uint32): JSObject {.importwasmexpr: "new Float32Array(_nima, $0, $1)".}
proc int32MemSlice(s: pointer, length: uint32): JSObject {.importwasmexpr: "new Int32Array(_nima, $0, $1)".}

proc glClearColorI(a, b, c, d: float32) {.importwasmf: "GLCtx.clearColor".}
proc glClearColor(a, b, c, d: float32) {.exportc.} = glClearColorI(a, b, c, d)

proc glGetErrorI(): uint32 {.importwasmf: "GLCtx.getError".}
proc glGetError(): uint32 {.exportc.} = glGetErrorI()

proc glClearI(a: uint32) {.importwasmf: "GLCtx.clear".}
proc glClear(a: uint32) {.exportc.} = glClearI(a)

proc glCreateProgramI(): JSObject {.importwasmf: "GLCtx.createProgram".}
proc glCreateProgram(): uint32 {.exportc.} = cast[uint32](storeExternRef(glCreateProgramI()))

proc glDeleteProgramI(h: JSObject) {.importwasmf: "GLCtx.deleteProgram".}
proc glDeleteProgram(h: uint32) {.exportc.} =
  let h = cast[JSRef](h)
  glDeleteProgramI(h)
  release(h)

proc glUseProgramI(h: JSObject) {.importwasmf: "window._wrtglap = $0;GLCtx.useProgram".}
proc glUseProgram(h: uint32) {.exportc.} = glUseProgramI(cast[JSRef](h))

proc glBindBufferI(a: uint32, b: JSObject) {.importwasmf: "GLCtx.bindBuffer".}
proc glBindBuffer(a, b: uint32) {.exportc.} = glBindBufferI(a, cast[JSRef](b))

proc glCreateShaderI(t: uint32): JSObject {.importwasmf: "GLCtx.createShader".}
proc glCreateShader(t: uint32): uint32 {.exportc.} = cast[uint32](storeExternRef(glCreateShaderI(t)))

proc glShaderSourceI(s: JSObject, c: cstring) {.importwasmf: "GLCtx.shaderSource".}
proc glShaderSource(p: uint32, c: int32, s: ptr UncheckedArray[cstring], l: ptr UncheckedArray[int32]) {.exportc.} =
  assert(c == 1)
  assert(l == nil)
  glShaderSourceI(cast[JSRef](p), s[0])

proc glCompileShaderI(t: JSObject) {.importwasmf: "GLCtx.compileShader".}
proc glCompileShader(t: uint32) {.exportc.} = glCompileShaderI(cast[JSRef](t))

proc glGetShaderParameteriI(s: JSObject, p: uint32): int32 {.importwasmf: "GLCtx.getShaderParameter"}
proc glGetShaderiv(s, p: uint32, v: ptr int32) {.exportc.} = v[] = glGetShaderParameteriI(cast[JSRef](s), p)

proc glAttachShaderI(s, p: JSObject) {.importwasmf: "GLCtx.attachShader"}
proc glAttachShader(s, p: uint32) {.exportc.} = glAttachShaderI(cast[JSRef](s), cast[JSRef](p))

proc glBindAttribLocationI(s: JSObject, p: uint32, l: cstring) {.importwasmf: "GLCtx.bindAttribLocation"}
proc glBindAttribLocation(s, p: uint32, l: cstring) {.exportc.} = glBindAttribLocationI(cast[JSRef](s), p, l)

proc glDeleteTextureI(h: JSObject) {.importwasmf: "GLCtx.deleteTexture".}
proc glDeleteTextureWasm(h: uint32) {.exportc.} =
  let h = cast[JSRef](h)
  glDeleteTextureI(h)
  release(h)

proc glDeleteTextures(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz:
    let h = cast[JSRef](tx[i])
    glDeleteTextureI(h)
    release(h)

proc glCreateTextureI(): JSObject {.importwasmf: "GLCtx.createTexture".}
proc glCreateTexture(): uint32 {.exportc.} =
  cast[uint32](storeExternRef(glCreateTextureI()))

proc glGenTextures(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateTexture()

proc glBindTextureI(s: uint32, p: JSObject) {.importwasmf: "GLCtx.bindTexture".}
proc glBindTexture(s, p: uint32) {.exportc.} = glBindTextureI(s, cast[JSRef](p))

proc glGenerateMipmapI(h: uint32) {.importwasmf: "GLCtx.generateMipmap".}
proc glGenerateMipmap(h: uint32) {.exportc.} = glGenerateMipmapI(h)

proc glTexParameteriI(s, p, h: uint32) {.importwasmf: "GLCtx.texParameteri".}
proc glTexParameteri(s, p, h: uint32) {.exportc.} = glTexParameteriI(s, p, h)

proc glTexParameterfI(s, p: uint32, h: float32) {.importwasmf: "GLCtx.texParameterf".}
proc glTexParameterf(s, p: uint32, h: float32) {.exportc.} = glTexParameterfI(s, p, h)

proc glDeleteShaderI(h: JSObject) {.importwasmf: "GLCtx.deleteShader".}
proc glDeleteShader(h: uint32) {.exportc.} =
  let h = cast[JSRef](h)
  glDeleteShaderI(h)
  release(h)

proc glLinkProgramI(h: JSObject) {.importwasmf: "GLCtx.linkProgram".}
proc glLinkProgram(h: uint32) {.exportc.} = glLinkProgramI(cast[JSRef](h))

proc glGetProgramParameteriI(s: JSObject, p: uint32): int32 {.importwasmf: "GLCtx.getProgramParameter"}
proc glGetProgramiv(s, p: uint32, v: ptr int32) {.exportc.} = v[] = glGetProgramParameteriI(cast[JSRef](s), p)

proc glEnableVertexAttribArrayI(i: uint32) {.importwasmf: "GLCtx.enableVertexAttribArray".}
proc glEnableVertexAttribArray(i: uint32) {.exportc.} = glEnableVertexAttribArrayI(i)

proc glDisableVertexAttribArrayI(i: uint32) {.importwasmf: "GLCtx.disableVertexAttribArray".}
proc glDisableVertexAttribArray(i: uint32) {.exportc.} = glDisableVertexAttribArrayI(i)

proc glVertexAttribPointerI(i: uint32, s: int32, t: uint32, n: bool, r: int32, o: pointer) {.importwasmf: "GLCtx.vertexAttribPointer".}
proc glVertexAttribPointer(i: uint32, s: int32, t: uint32, n: bool, r: int32, o: pointer) {.exportc.} =
  glVertexAttribPointerI(i, s, t, n, r, o)

proc getUniformLocationObj(l: uint32): JSObject {.importwasmexpr: "_wrtglap._nimu[$0]".}

proc glUniformMatrix4fvI(l: JSObject, t: bool, v: JSObject) {.importwasmf: "GLCtx.uniformMatrix4fv".}
proc glUniformMatrix4fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix4")
  glUniformMatrix4fvI(getUniformLocationObj(l), t, float32MemSlice(v, 16))

proc glUniformMatrix3fvI(l: JSObject, t: bool, v: JSObject) {.importwasmf: "GLCtx.uniformMatrix3fv".}
proc glUniformMatrix3fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix3")
  glUniformMatrix3fvI(getUniformLocationObj(l), t, float32MemSlice(v, 9))

proc glUniformMatrix2fvI(l: JSObject, t: bool, v: JSObject) {.importwasmf: "GLCtx.uniformMatrix2fv".}
proc glUniformMatrix2fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix2")
  glUniformMatrix2fvI(getUniformLocationObj(l), t, float32MemSlice(v, 4))

proc glGetUniformLocationI(h: JSObject, n: cstring): uint32 {.importwasmraw: """
  $0._nimun ||= {};
  var r = $0._nimun[$1];
  if (r === undefined) {
    $0._nimu ||= [];
    r = $0._nimun[$1] = $0._nimu.push(GLCtx.getUniformLocation($0, $1)) - 1
  }
  return r
  """.}
proc glGetUniformLocation(h: uint32, n: cstring): uint32 {.exportc.} = glGetUniformLocationI(cast[JSRef](h), n)

proc glUniform1fI(l: JSObject, v: float32) {.importwasmf: "GLCtx.uniform1f".}
proc glUniform1f(l: uint32, v: float32) {.exportc.} = glUniform1fI(getUniformLocationObj(l), v)

proc glUniform1iI(l: JSObject, v: int32) {.importwasmf: "GLCtx.uniform1i".}
proc glUniform1i(l: uint32, v: int32) {.exportc.} = glUniform1iI(getUniformLocationObj(l), v)

proc glUniform1fvI(l: JSObject, b: JSObject) {.importwasmf: "GLCtx.uniform1fv".}
proc glUniform1fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform1fvI(getUniformLocationObj(l), float32MemSlice(v, c * 1))

proc glUniform2fvI(l: JSObject, b: JSObject) {.importwasmf: "GLCtx.uniform2fv".}
proc glUniform2fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform2fvI(getUniformLocationObj(l), float32MemSlice(v, c * 2))

proc glUniform3fvI(l: JSObject, b: JSObject) {.importwasmf: "GLCtx.uniform3fv".}
proc glUniform3fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform3fvI(getUniformLocationObj(l), float32MemSlice(v, c * 3))

proc glUniform4fvI(l: JSObject, b: JSObject) {.importwasmf: "GLCtx.uniform4fv".}
proc glUniform4fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform4fvI(getUniformLocationObj(l), float32MemSlice(v, c * 4))

proc glDrawArraysI(m, f, c: uint32) {.importwasmf: "GLCtx.drawArrays".}
proc glDrawArrays(m, f, c: uint32) {.exportc.} = glDrawArraysI(m, f, c)

proc glEnableI(v: uint32) {.importwasmf: "GLCtx.enable".}
proc glEnable(v: uint32) {.exportc.} = glEnableI(v)

proc glDisableI(v: uint32) {.importwasmf: "GLCtx.disable".}
proc glDisable(v: uint32) {.exportc.} = glDisableI(v)

proc glColorMaskI(r, g, b, a: bool) {.importwasmf: "GLCtx.colorMask".}
proc glColorMask(r, g, b, a: bool) {.exportc.} = glColorMaskI(r, g, b, a)

proc glDepthMaskI(f: bool) {.importwasmf: "GLCtx.depthMask".}
proc glDepthMask(f: bool) {.exportc.} = glDepthMaskI(f)

proc glStencilMaskI(f: uint32) {.importwasmf: "GLCtx.stencilMask".}
proc glStencilMask(f: uint32) {.exportc.} = glStencilMaskI(f)

proc glStencilOpI(a, b, c: uint32) {.importwasmf: "GLCtx.stencilOp".}
proc glStencilOp(a, b, c: uint32) {.exportc.} = glStencilOpI(a, b, c)

proc glStencilFuncI(a, b, c: uint32) {.importwasmf: "GLCtx.stencilFunc".}
proc glStencilFunc(a, b, c: uint32) {.exportc.} = glStencilFuncI(a, b, c)

proc glBlendColorI(r, g, b, a: float32) {.importwasmf: "GLCtx.blendColor".}
proc glBlendColor(r, g, b, a: float32) {.exportc.} = glBlendColorI(r, g, b, a)

proc glBlendFuncI(a, b: uint32) {.importwasmf: "GLCtx.blendFunc".}
proc glBlendFunc(a, b: uint32) {.exportc.} = glBlendFuncI(a, b)

proc glActiveTextureI(a: uint32) {.importwasmf: "GLCtx.activeTexture".}
proc glActiveTexture(a: uint32) {.exportc.} = glActiveTextureI(a)

proc glBufferDataI(t: uint32, d: JSObject, u: uint32) {.importwasmf: "GLCtx.bufferData".}
proc glBufferData(t, s: uint32, d: pointer, u: uint32) {.exportc.} =
  glBufferDataI(t, uint8MemSlice(d, s), u)

proc glDrawElementsI(a, b, c, d: uint32) {.importwasmf: "GLCtx.drawElements".}
proc glDrawElements(a, b, c, d: uint32) {.exportc.} = glDrawElementsI(a, b, c, d)

proc glPixelStoreiI(a, b: uint32) {.importwasmf: "GLCtx.pixelStorei".}
proc glPixelStorei(a, b: uint32) {.exportc.} = glPixelStoreiI(a, b)

proc glTexImage2DI(t: uint32, l, i: int32, w, h, b: int32, f, k: uint32, p: JSObject) {.importwasmf: "GLCtx.texImage2D".}
import strutils

proc componentsInFormat(f: uint32): int32 =
  case f
  of 0x1906, 0x1909: 1 # ALPHA, LUMINANCE
  of 0x190A: 2 # LUMINANCE_ALPHA
  of 0x1907: 3 # RGB
  of 0x1908: 4 # RGBA
  else:
    # echo "unknown format: ", toHex(f)
    assert(false, "Unknown format " & toHex(f))
    0

proc bytesInComponentTyp(t: uint32): int32 =
  case t
  of 0x1401: 1 # UNSIGNED_BYTE
  else:
    # echo "unknown typ: ", toHex(t)
    assert(false, "Unknown typ " & toHex(t))
    0
  
proc bytesInPixel(format, typ: uint32): int32 =
  componentsInFormat(format) * bytesInComponentTyp(typ)

proc nullExternRef(): JSObject {.importc: "__builtin_wasm_ref_null_extern", nodecl.}
proc glTexImage2D(target: uint32, level, internalFormat: int32, width, height, border: int32, format, typ: uint32, data: pointer) {.exportc.} =
  let m = if data != nil:
            uint8MemSlice(data, uint32(width * height * bytesInPixel(format, typ)))
          else:
            nullExternRef()
  glTexImage2DI(target, level, internalFormat, width, height, border, format, typ, m)

proc glTexSubImage2DI(t: uint32, l, x, y: int32, w, h: int32, f, k: uint32, p: JSObject) {.importwasmf: "GLCtx.texSubImage2D".}

proc glTexSubImage2D(target: uint32, level, xoffset, yoffset: int32, width, height: int32, format, typ: uint32, data: pointer) {.exportc.} =
  let m = uint8MemSlice(data, uint32(width * height * bytesInPixel(format, typ)))
  glTexSubImage2DI(target, level, xoffset, yoffset, width, height, format, typ, m)

proc glBlendFuncSeparateI(a, b, c, d: uint32) {.importwasmf: "GLCtx.blendFuncSeparate".}
proc glBlendFuncSeparate(a, b, c, d: uint32) {.exportc.} = glBlendFuncSeparateI(a, b, c, d)

proc glDeleteFramebufferI(h: JSObject) {.importwasmf: "GLCtx.deleteFramebuffer".}
proc glDeleteFramebuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz:
    let h = cast[JSRef](tx[i])
    glDeleteFramebufferI(h)
    release(h)

proc glDeleteRenderbufferI(h: JSObject) {.importwasmf: "GLCtx.deleteRenderbuffer".}
proc glDeleteRenderbuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz:
    let h = cast[JSRef](tx[i])
    glDeleteRenderbufferI(h)
    release(h)

proc glCreateFramebufferI(): JSObject {.importwasmf: "GLCtx.createFramebuffer".}
proc glCreateFramebuffer(): uint32 {.exportc.} = cast[uint32](storeExternRef(glCreateFramebufferI()))
proc glGenFramebuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateFramebuffer()

proc glCreateBufferI(): JSObject {.importwasmf: "GLCtx.createBuffer".}
proc glCreateBuffer(): uint32 {.exportc.} = cast[uint32](storeExternRef(glCreateBufferI()))
proc glGenBuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateBuffer()

proc glBindFramebufferI(a: uint32, b: JSObject) {.importwasmf: "GLCtx.bindFramebuffer".}
proc glBindFramebuffer(a, b: uint32) {.exportc.} = glBindFramebufferI(a, cast[JSRef](b))

proc glCreateRenderbufferI(): JSObject {.importwasmf: "GLCtx.createRenderbuffer".}
proc glCreateRenderbuffer(): uint32 {.exportc.} = cast[uint32](storeExternRef(glCreateRenderbufferI()))
proc glGenRenderbuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateRenderbuffer()

proc glBindRenderbufferI(a: uint32, b: JSObject) {.importwasmf: "GLCtx.bindRenderbuffer".}
proc glBindRenderbuffer(a, b: uint32) {.exportc.} = glBindRenderbufferI(a, cast[JSRef](b))

proc glRenderbufferStorageI(a, b: uint32, c, d: int32) {.importwasmf: "GLCtx.renderbufferStorage".}
proc glRenderbufferStorage(a, b: uint32, c, d: int32) {.exportc.} = glRenderbufferStorageI(a, b, c, d)

proc glFramebufferRenderbufferI(a, b, c: uint32, d: JSObject) {.importwasmf: "GLCtx.framebufferRenderbuffer".}
proc glFramebufferRenderbuffer(a, b, c, d: uint32) {.exportc.} = glFramebufferRenderbufferI(a, b, c, cast[JSRef](d))

proc glFramebufferTexture2DI(a, b, c: uint32, d: JSObject, e: int32) {.importwasmf: "GLCtx.framebufferTexture2D".}
proc glFramebufferTexture2D(a, b, c, d: uint32, e: int32) {.exportc.} = glFramebufferTexture2DI(a, b, c, cast[JSRef](d), e)

proc glGetParameter(a: uint32): JSObject {.importwasmf: "GLCtx.getParameter".}
proc length(a: JSObject): uint32 {.importwasmp: "length|0".}
proc setMem(a, b: JSObject) {.importwasmm: "set".}
proc jsObjToInt(o: JSObject): int32 {.importwasmexpr: "$0".}
proc jsObjToFloat(o: JSObject): float32 {.importwasmexpr: "$0".}

proc glGetIntegerv(a: uint32, v: ptr int32) {.exportc.} =
  let p = glGetParameter(a)
  let sz = p.length
  if sz == 0:
    v[] = jsObjToInt(p)
  else:
    setMem(int32MemSlice(v, sz), p)

proc glGetBooleanv(a: uint32, v: ptr bool) {.exportc.} =
  v[] = jsObjToInt(glGetParameter(a)).bool

proc glGetFloatv(a: uint32, v: ptr float32) {.exportc.} =
  let p = glGetParameter(a)
  let sz = p.length
  if sz == 0:
    v[] = jsObjToFloat(p)
  else:
    setMem(float32MemSlice(v, sz), p)

proc glViewportI(a, b, c, d: uint32) {.importwasmf: "GLCtx.viewport".}
proc glViewport(a, b, c, d: uint32) {.exportc.} = glViewportI(a, b, c, d)

proc glGetShaderInfoLogI(s: JSObject): JSString {.importwasmf: "GLCtx.getShaderInfoLog".}
proc glGetProgramInfoLogI(s: JSObject): JSString {.importwasmf: "GLCtx.getProgramInfoLog".}

proc jsStrToMem(s: JSString, maxLen: int32, length: ptr int32, infoLog: ptr char) =
  let s = $s
  var sz = s.len.int32
  if maxLen < sz:
    sz = maxLen
  if length != nil:
    length[] = sz
  if infoLog != nil and sz != 0:
    copyMem(infoLog, addr s[0], sz)

proc glGetShaderInfoLog(s: uint32, maxLength: int32, length: ptr int32, infoLog: ptr char) {.exportc.} =
  jsStrToMem(glGetShaderInfoLogI(cast[JSRef](s)), maxLength, length, infoLog)
proc glGetProgramInfoLog(s: uint32, maxLength: int32, length: ptr int32, infoLog: ptr char) {.exportc.} =
  jsStrToMem(glGetProgramInfoLogI(cast[JSRef](s)), maxLength, length, infoLog)

{.pop.} # stackTrace:off

