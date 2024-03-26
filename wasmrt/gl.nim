import ../wasmrt

{.push stackTrace:off.}

proc glClearColorI(a, b, c, d: float32) {.importwasmf: "GLCtx.clearColor".}
proc glClearColor(a, b, c, d: float32) {.exportc.} = glClearColorI(a, b, c, d)

proc glGetErrorI(): uint32 {.importwasmf: "GLCtx.getError".}
proc glGetError(): uint32 {.exportc.} = glGetErrorI()

proc glClearI(a: uint32) {.importwasmf: "GLCtx.clear".}
proc glClear(a: uint32) {.exportc.} = glClearI(a)

proc glCreateProgramI(): JSRef {.importwasmf: "GLCtx.createProgram".}
proc glCreateProgram(): uint32 {.exportc.} = cast[uint32](glCreateProgramI())

proc glDeleteProgramI(h: JSRef) {.importwasmf: "GLCtx.deleteProgram".}
proc glDeleteProgram(h: uint32) {.exportc.} =
  let h = cast[JSRef](h)
  glDeleteProgramI(h)
  delete(h)

proc glUseProgramI(h: uint32) {.importwasmraw: "window._wrtglap = _nimo[$0];GLCtx.useProgram(_wrtglap)".}
proc glUseProgram(h: uint32) {.exportc.} = glUseProgramI(h)

proc glBindBufferI(a: uint32, b: JSRef) {.importwasmf: "GLCtx.bindBuffer".}
proc glBindBuffer(a, b: uint32) {.exportc.} = glBindBufferI(a, cast[JSRef](b))

proc glCreateShaderI(t: uint32): JSRef {.importwasmf: "GLCtx.createShader".}
proc glCreateShader(t: uint32): uint32 {.exportc.} = cast[uint32](glCreateShaderI(t))

proc glShaderSourceI(s: JSRef, c: cstring) {.importwasmf: "GLCtx.shaderSource".}
proc glShaderSource(p: uint32, c: int32, s: ptr UncheckedArray[cstring], l: ptr UncheckedArray[int32]) {.exportc.} =
  assert(c == 1)
  assert(l == nil)
  glShaderSourceI(cast[JSRef](p), s[0])

proc glCompileShaderI(t: JSRef) {.importwasmf: "GLCtx.compileShader".}
proc glCompileShader(t: uint32) {.exportc.} = glCompileShaderI(cast[JSRef](t))

proc glGetShaderParameteriI(s: JSRef, p: uint32): int32 {.importwasmf: "GLCtx.getShaderParameter"}
proc glGetShaderiv(s, p: uint32, v: ptr int32) {.exportc.} = v[] = glGetShaderParameteriI(cast[JSRef](s), p)

proc glAttachShaderI(s, p: JSRef) {.importwasmf: "GLCtx.attachShader"}
proc glAttachShader(s, p: uint32) {.exportc.} = glAttachShaderI(cast[JSRef](s), cast[JSRef](p))

proc glBindAttribLocationI(s: JSRef, p: uint32, l: cstring) {.importwasmf: "GLCtx.bindAttribLocation"}
proc glBindAttribLocation(s, p: uint32, l: cstring) {.exportc.} = glBindAttribLocationI(cast[JSRef](s), p, l)

proc glDeleteTextureI(h: JSRef) {.importwasmf: "GLCtx.deleteTexture".}
proc glDeleteTextureWasm(h: uint32) {.exportc.} =
  let h = cast[JSRef](h)
  glDeleteTextureI(h)
  delete(h)

proc glDeleteTextures(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz:
    let h = cast[JSRef](tx[i])
    glDeleteTextureI(h)
    delete(h)

proc glCreateTextureI(): JSRef {.importwasmf: "GLCtx.createTexture".}
proc glCreateTexture(): uint32 {.exportc.} = cast[uint32](glCreateTextureI())

proc glGenTextures(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = cast[uint32](glCreateTextureI())

proc glBindTextureI(s: uint32, p: JSRef) {.importwasmf: "GLCtx.bindTexture".}
proc glBindTexture(s, p: uint32) {.exportc.} = glBindTextureI(s, cast[JSRef](p))

proc glGenerateMipmapI(h: uint32) {.importwasmf: "GLCtx.generateMipmap".}
proc glGenerateMipmap(h: uint32) {.exportc.} = glGenerateMipmapI(h)

proc glTexParameteriI(s, p, h: uint32) {.importwasmf: "GLCtx.texParameteri".}
proc glTexParameteri(s, p, h: uint32) {.exportc.} = glTexParameteriI(s, p, h)

proc glTexParameterfI(s, p: uint32, h: float32) {.importwasmf: "GLCtx.texParameterf".}
proc glTexParameterf(s, p: uint32, h: float32) {.exportc.} = glTexParameterfI(s, p, h)

proc glDeleteShaderI(h: JSRef) {.importwasmf: "GLCtx.deleteShader".}
proc glDeleteShader(h: uint32) {.exportc.} =
  let h = cast[JSRef](h)
  glDeleteShaderI(h)
  delete(h)

proc glLinkProgramI(h: JSRef) {.importwasmf: "GLCtx.linkProgram".}
proc glLinkProgram(h: uint32) {.exportc.} = glLinkProgramI(cast[JSRef](h))

proc glGetProgramParameteriI(s: JSRef, p: uint32): int32 {.importwasmf: "GLCtx.getProgramParameter"}
proc glGetProgramiv(s, p: uint32, v: ptr int32) {.exportc.} = v[] = glGetProgramParameteriI(cast[JSRef](s), p)

proc glEnableVertexAttribArrayI(i: uint32) {.importwasmf: "GLCtx.enableVertexAttribArray".}
proc glEnableVertexAttribArray(i: uint32) {.exportc.} = glEnableVertexAttribArrayI(i)

proc glDisableVertexAttribArrayI(i: uint32) {.importwasmf: "GLCtx.disableVertexAttribArray".}
proc glDisableVertexAttribArray(i: uint32) {.exportc.} = glDisableVertexAttribArrayI(i)

proc glVertexAttribPointerI(i: uint32, s: int32, t: uint32, n: bool, r: int32, o: pointer) {.importwasmf: "GLCtx.vertexAttribPointer".}
proc glVertexAttribPointer(i: uint32, s: int32, t: uint32, n: bool, r: int32, o: pointer) {.exportc.} =
  glVertexAttribPointerI(i, s, t, n, r, o)

proc glUniformMatrix4fvI(l: uint32, t: bool, v: ptr float32) {.importwasmraw: "GLCtx.uniformMatrix4fv(_wrtglap._nimu[$0], $1, new Float32Array(_nima, $2, 16))".}
proc glUniformMatrix4fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix4")
  glUniformMatrix4fvI(l, t, v)

proc glUniformMatrix3fvI(l: uint32, t: bool, v: ptr float32) {.importwasmraw: "GLCtx.uniformMatrix3fv(_wrtglap._nimu[$0], $1, new Float32Array(_nima, $2, 9))".}
proc glUniformMatrix3fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix3")
  glUniformMatrix3fvI(l, t, v)

proc glUniformMatrix2fvI(l: uint32, t: bool, v: ptr float32) {.importwasmraw: "GLCtx.uniformMatrix2fv(_wrtglap._nimu[$0], $1, new Float32Array(_nima, $2, 4))".}
proc glUniformMatrix2fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix2")
  glUniformMatrix2fvI(l, t, v)

proc glGetUniformLocationI(h: uint32, n: cstring): uint32 {.importwasmraw: """
  var p = _nimo[$0], N = _nimsj($1);
  p._nimun ||= {};
  var r = p._nimun[N];
  if (r === undefined) {
    p._nimu ||= [];
    r = p._nimun[N] = p._nimu.push(GLCtx.getUniformLocation(p, N)) - 1
  }
  return r
  """.}
proc glGetUniformLocation(h: uint32, n: cstring): uint32 {.exportc.} = glGetUniformLocationI(h, n)

proc glUniform1fI(l: uint32, v: float32) {.importwasmraw: "GLCtx.uniform1f(_wrtglap._nimu[$0], $1)".}
proc glUniform1f(l: uint32, v: float32) {.exportc.} = glUniform1fI(l, v)

proc glUniform1iI(l: uint32, v: int32) {.importwasmraw: "GLCtx.uniform1i(_wrtglap._nimu[$0], $1)".}
proc glUniform1i(l: uint32, v: int32) {.exportc.} = glUniform1iI(l, v)

proc glUniform1fvI(l: uint32, b: ptr float32, s: uint32) {.importwasmraw: "GLCtx.uniform1fv(_wrtglap._nimu[$0], new Float32Array(_nima, $1, $2))".}
proc glUniform1fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform1fvI(l, v, c * 1)

proc glUniform2fvI(l: uint32, b: ptr float32, s: uint32) {.importwasmraw: "GLCtx.uniform2fv(_wrtglap._nimu[$0], new Float32Array(_nima, $1, $2))".}
proc glUniform2fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform2fvI(l, v, c * 2)

proc glUniform3fvI(l: uint32, b: ptr float32, s: uint32) {.importwasmraw: "GLCtx.uniform3fv(_wrtglap._nimu[$0], new Float32Array(_nima, $1, $2))".}
proc glUniform3fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform3fvI(l, v, c * 3)

proc glUniform4fvI(l: uint32, b: ptr float32, s: uint32) {.importwasmraw: "GLCtx.uniform4fv(_wrtglap._nimu[$0], new Float32Array(_nima, $1, $2))".}
proc glUniform4fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform4fvI(l, v, c * 4)

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

proc glBufferDataI(t, s: uint32, d: pointer, u: uint32) {.importwasmraw: "GLCtx.bufferData($0, new DataView(_nima, $2, $1), $3)".}
proc glBufferData(t, s: uint32, d: pointer, u: uint32) {.exportc.} = glBufferDataI(t, s, d, u)

proc glDrawElementsI(a, b, c, d: uint32) {.importwasmf: "GLCtx.drawElements".}
proc glDrawElements(a, b, c, d: uint32) {.exportc.} = glDrawElementsI(a, b, c, d)

# proc glTexSubImage2DI() {.importwasmraw: "".}
# proc glTexSubImage2D() {.exportc.} = glTexSubImage2DI()

proc glPixelStoreiI(a, b: uint32) {.importwasmf: "GLCtx.pixelStorei".}
proc glPixelStorei(a, b: uint32) {.exportc.} = glPixelStoreiI(a, b)

proc glTexImage2DUint8I(t: uint32, l, i: int32, w, h, b: int32, f, k: uint32, s: int32, p: pointer) {.importwasmraw: """
  GLCtx.texImage2D($0, $1, $2, $3, $4, $5, $6, $7, new Uint8Array(_nima, $9, $8))
  """.}
import strutils

proc bytesInFormat(f: uint32): int32 =
  case f
  of 0x1906, 0x1909: # ALPHA, LUMINANCE
    1
  of 0x190A: # LUMINANCE_ALPHA
    2
  of 0x1907: # RGB
    3
  of 0x1908: # RGBA
    4
  else:
    echo "unknown format: ", toHex(f)
    assert(false, "Unknown format " & $f)
    0

proc glTexImage2D(target: uint32, level, internalFormat: int32, width, height, border: int32, format, typ: uint32, data: pointer) {.exportc.} =
  case typ
  of 0x1401: # UNSIGNED_BYTE
    glTexImage2DUint8I(target, level, internalFormat, width, height, border, format, typ, width * height * bytesInFormat(format), data)
  else:
    echo "unknown typ: ", toHex(format)
    assert(false, "Unknown typ " & $format)

proc glTexSubImage2DUint8I(t: uint32, l, x, y: int32, w, h: int32, f, k: uint32, s: int32, p: pointer) {.importwasmraw: """
  GLCtx.texSubImage2D($0, $1, $2, $3, $4, $5, $6, $7, new Uint8Array(_nima, $9, $8))
  """.}

proc glTexSubImage2D(target: uint32, level, xoffset, yoffset: int32, width, height: int32, format, typ: uint32, data: pointer) {.exportc.} =
  case typ
  of 0x1401: # UNSIGNED_BYTE
    glTexSubImage2DUint8I(target, level, xoffset, yoffset, width, height, format, typ, width * height * bytesInFormat(format), data)
  # of 0x8363: # UNSIGNED_SHORT_5_6_5
  else:
    echo "unknown typ: ", toHex(format)
    assert(false, "Unknown typ " & $format)


proc glBlendFuncSeparateI(a, b, c, d: uint32) {.importwasmf: "GLCtx.blendFuncSeparate".}
proc glBlendFuncSeparate(a, b, c, d: uint32) {.exportc.} = glBlendFuncSeparateI(a, b, c, d)

proc glDeleteFramebufferI(h: JSRef) {.importwasmf: "GLCtx.deleteFramebuffer".}
proc glDeleteFramebuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz:
    let h = cast[JSRef](tx[i])
    glDeleteFramebufferI(h)
    delete(h)

proc glDeleteRenderbufferI(h: JSRef) {.importwasmf: "GLCtx.deleteRenderbuffer".}
proc glDeleteRenderbuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz:
    let h = cast[JSRef](tx[i])
    glDeleteRenderbufferI(h)
    delete(h)

proc glCreateFramebufferI(): JSRef {.importwasmf: "GLCtx.createFramebuffer".}
proc glCreateFramebuffer(): uint32 {.exportc.} = cast[uint32](glCreateFramebufferI())
proc glGenFramebuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = cast[uint32](glCreateFramebufferI())

proc glCreateBufferI(): JSRef {.importwasmf: "GLCtx.createBuffer".}
proc glCreateBuffer(): uint32 {.exportc.} = cast[uint32](glCreateBufferI())
proc glGenBuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = cast[uint32](glCreateBufferI())

proc glBindFramebufferI(a: uint32, b: JSRef) {.importwasmf: "GLCtx.bindFramebuffer".}
proc glBindFramebuffer(a, b: uint32) {.exportc.} = glBindFramebufferI(a, cast[JSRef](b))

proc glCreateRenderbufferI(): JSRef {.importwasmf: "GLCtx.createRenderbuffer".}
proc glCreateRenderbuffer(): uint32 {.exportc.} = cast[uint32](glCreateRenderbufferI())
proc glGenRenderbuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = cast[uint32](glCreateRenderbufferI())

proc glBindRenderbufferI(a: uint32, b: JSRef) {.importwasmf: "GLCtx.bindRenderbuffer".}
proc glBindRenderbuffer(a, b: uint32) {.exportc.} = glBindRenderbufferI(a, cast[JSRef](b))

# proc glRenderbufferStorageI() {.importwasmraw: "".}
# proc glRenderbufferStorage() {.exportc.} = glRenderbufferStorageI()

proc glFramebufferRenderbufferI(a, b, c: uint32, d: JSRef) {.importwasmf: "GLCtx.framebufferRenderbuffer".}
proc glFramebufferRenderbuffer(a, b, c, d: uint32) {.exportc.} = glFramebufferRenderbufferI(a, b, c, cast[JSRef](d))

# proc glFramebufferTexture2DI() {.importwasmraw: "".}
# proc glFramebufferTexture2D() {.exportc.} = glFramebufferTexture2DI()

proc glGetIntegervI(a: uint32, v: ptr int32) {.importwasmraw: """
  var o = GLCtx.getParameter($0);
  _nimwi(o['length'] == undefined ? [o] : o, $1)
  """.}
proc glGetIntegerv(a: uint32, v: ptr int32) {.exportc.} = glGetIntegervI(a, v)

proc glGetBooleanvI(a: uint32): int32 {.importwasmf: "!!GLCtx.getParam".}
proc glGetBooleanv(a: uint32, v: ptr bool) {.exportc.} = v[] = glGetBooleanvI(a) != 0

proc glGetFloatvI(a: uint32, v: ptr float32) {.importwasmraw: """
  var o = GLCtx.getParameter($0);
  _nimwf(o['length'] == undefined ? [o] : o, $1)
  """.}
proc glGetFloatv(a: uint32, v: ptr float32) {.exportc.} = glGetFloatvI(a, v)

proc glViewportI(a, b, c, d: uint32) {.importwasmf: "GLCtx.viewport".}
proc glViewport(a, b, c, d: uint32) {.exportc.} = glViewportI(a, b, c, d)

proc glGetInfoLogI(p: int32, s: uint32, m: int32, l: ptr int32, i: ptr char) {.importwasmraw:"""
  var o = GLCtx[$0?'getShaderInfoLog':'getProgramInfoLog'](_nimo[$1]);
  if ($3) _nimwi([o.length], $3);
  if ($4) _nimws(o, $4, $2);
  """.}
proc glGetShaderInfoLog(s: uint32, maxLength: int32, length: ptr int32, infoLog: ptr char) {.exportc.} =
  glGetInfoLogI(1, s, maxLength, length, infoLog)
proc glGetProgramInfoLog(s: uint32, maxLength: int32, length: ptr int32, infoLog: ptr char) {.exportc.} =
  glGetInfoLogI(0, s, maxLength, length, infoLog)

{.pop.} # stackTrace:off

