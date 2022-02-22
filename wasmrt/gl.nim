import ../wasmrt

proc wasmrtInitGl() {.importwasm: """
var w = window;
w._wrtglp = [null];
w._wrti = (b) => {var a = _wrtglp, r = a.length; a[r] = b; return r};
w._wrtglap = null;
""".}

proc glClearColorI(a, b, c, d: float32) {.importwasm: "GLCtx.clearColor(a, b, c, d)".}
proc glClearColor(a, b, c, d: float32) {.exportc.} = glClearColorI(a, b, c, d)

proc glGetErrorI(): uint32 {.importwasm: "GLCtx.getError()".}
proc glGetError(): uint32 {.exportc.} = glGetErrorI()

proc glClearI(a: uint32) {.importwasm: "GLCtx.clear(a)".}
proc glClear(a: uint32) {.exportc.} = glClearI(a)

proc glCreateProgramI(): uint32 {.importwasm: "return _wrti(GLCtx.createProgram())".}
proc glCreateProgram(): uint32 {.exportc.} = glCreateProgramI()

proc glDeleteProgramI(h: uint32) {.importwasm: "var p = _wrtglp[h]; delete _wrtglp[h]; GLCtx.deleteProgram(p)".}
proc glDeleteProgram(h: uint32) {.exportc.} = glDeleteProgramI(h)

proc glUseProgramI(h: uint32) {.importwasm: "window._wrtglap = _wrtglp[h];GLCtx.useProgram(_wrtglap)".}
proc glUseProgram(h: uint32) {.exportc.} = glUseProgramI(h)

proc glBindBufferI(a, b: uint32) {.importwasm: "GLCtx.bindBuffer(a, _wrtglp[b])".}
proc glBindBuffer(a, b: uint32) {.exportc.} = glBindBufferI(a, b)

proc glCreateShaderI(t: uint32): uint32 {.importwasm: "return _wrti(GLCtx.createShader(t))".}
proc glCreateShader(t: uint32): uint32 {.exportc.} = glCreateShaderI(t)

proc glShaderSourceI(s: uint32, c: cstring) {.importwasm: "GLCtx.shaderSource(_wrtglp[s], _nimsj(c))".}
proc glShaderSource(p: uint32, c: int32, s: ptr UncheckedArray[cstring], l: ptr UncheckedArray[int32]) {.exportc.} =
  assert(c == 1)
  assert(l == nil)
  glShaderSourceI(p, s[0])

proc glCompileShaderI(t: uint32) {.importwasm: "GLCtx.compileShader(_wrtglp[t])".}
proc glCompileShader(t: uint32) {.exportc.} = glCompileShaderI(t)

proc glGetShaderParameteriI(s, p: uint32): int32 {.importwasm: "return GLCtx.getShaderParameter(_wrtglp[s], p)"}
proc glGetShaderiv(s, p: uint32, v: ptr int32) {.exportc.} = v[] = glGetShaderParameteriI(s, p)

proc glAttachShaderI(s, p: uint32) {.importwasm: "GLCtx.attachShader(_wrtglp[s], _wrtglp[p])"}
proc glAttachShader(s, p: uint32) {.exportc.} = glAttachShaderI(s, p)

proc glBindAttribLocationI(s, p: uint32, l: cstring) {.importwasm: "GLCtx.bindAttribLocation(_wrtglp[s], p, _nimsj(l))"}
proc glBindAttribLocation(s, p: uint32, l: cstring) {.exportc.} = glBindAttribLocationI(s, p, l)

proc glDeleteTextureI(h: uint32) {.importwasm: "var p = _wrtglp[h]; delete _wrtglp[h]; GLCtx.deleteTexture(p)".}
proc glDeleteTextureWasm(h: uint32) {.exportc.} = glDeleteTextureI(h)

proc glDeleteTextures(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: glDeleteTextureI(tx[i])

proc glCreateTextureI(): uint32 {.importwasm: "return _wrti(GLCtx.createTexture())".}
proc glCreateTexture(): uint32 {.exportc.} = glCreateTextureI()

proc glGenTextures(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateTextureI()

proc glBindTextureI(s, p: uint32): uint32 {.importwasm: "GLCtx.bindTexture(s, _wrtglp[p])".}
proc glBindTexture(s, p: uint32): uint32 {.exportc.} = glBindTextureI(s, p)

proc glGenerateMipmapI(h: uint32) {.importwasm: "GLCtx.generateMipmap(h)".}
proc glGenerateMipmap(h: uint32) {.exportc.} = glGenerateMipmapI(h)

proc glTexParameteriI(s, p, h: uint32) {.importwasm: "GLCtx.texParameteri(s, p, h)".}
proc glTexParameteri(s, p, h: uint32) {.exportc.} = glTexParameteriI(s, p, h)

proc glTexParameterfI(s, p: uint32, h: float32) {.importwasm: "GLCtx.texParameterf(s, p, h)".}
proc glTexParameterf(s, p: uint32, h: float32) {.exportc.} = glTexParameterfI(s, p, h)

proc glDeleteShaderI(h: uint32) {.importwasm: "var p = _wrtglp[h]; delete _wrtglp[h]; GLCtx.deleteShader(p)".}
proc glDeleteShader(h: uint32) {.exportc.} = glDeleteShaderI(h)

proc glLinkProgramI(h: uint32) {.importwasm: "GLCtx.linkProgram(_wrtglp[h])".}
proc glLinkProgram(h: uint32) {.exportc.} = glLinkProgramI(h)

proc glGetProgramParameteriI(s, p: uint32): int32 {.importwasm: "return GLCtx.getProgramParameter(_wrtglp[s], p)"}
proc glGetProgramiv(s, p: uint32, v: ptr int32) {.exportc.} = v[] = glGetProgramParameteriI(s, p)

proc glEnableVertexAttribArrayI(i: uint32) {.importwasm: "GLCtx.enableVertexAttribArray(i)".}
proc glEnableVertexAttribArray(i: uint32) {.exportc.} = glEnableVertexAttribArrayI(i)

proc glDisableVertexAttribArrayI(i: uint32) {.importwasm: "GLCtx.disableVertexAttribArray(i)".}
proc glDisableVertexAttribArray(i: uint32) {.exportc.} = glDisableVertexAttribArrayI(i)

proc glVertexAttribPointerI(i: uint32, s: int32, t: uint32, n: bool, r: int32, o: pointer) {.importwasm: "GLCtx.vertexAttribPointer(i, s, t, n, r, o)".}
proc glVertexAttribPointer(i: uint32, s: int32, t: uint32, n: bool, r: int32, o: pointer) {.exportc.} =
  glVertexAttribPointerI(i, s, t, n, r, o)

proc glUniformMatrix4fvI(l, c: uint32, t: bool, v: ptr float32) {.importwasm: "GLCtx.uniformMatrix4fv(_wrtglap._nimu[l], t, new Float32Array(_nima.buffer, v, 16))".}
proc glUniformMatrix4fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix4")
  glUniformMatrix4fvI(l, c, t, v)

proc glUniformMatrix3fvI(l, c: uint32, t: bool, v: ptr float32) {.importwasm: "GLCtx.uniformMatrix3fv(_wrtglap._nimu[l], t, new Float32Array(_nima.buffer, v, 9))".}
proc glUniformMatrix3fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix3")
  glUniformMatrix3fvI(l, c, t, v)

proc glUniformMatrix2fvI(l, c: uint32, t: bool, v: ptr float32) {.importwasm: "GLCtx.uniformMatrix2fv(_wrtglap._nimu[l], t, new Float32Array(_nima.buffer, v, 4))".}
proc glUniformMatrix2fv(l, c: uint32, t: bool, v: ptr float32) {.exportc.} =
  assert(c == 1, "c != 1 not supported in glUniformMatrix2")
  glUniformMatrix2fvI(l, c, t, v)

proc glGetUniformLocationI(h: uint32, n: cstring): uint32 {.importwasm: """
  var p = _wrtglp[h], N = _nimsj(n);
  p._nimun ||= {};
  var r = p._nimun[N];
  if (r === undefined) {
    p._nimu ||= [];
    r = p._nimu.length;
    p._nimu[r] = GLCtx.getUniformLocation(p, N);
    p._nimun[N] = r;
  }
  return r
  """.}
proc glGetUniformLocation(h: uint32, n: cstring): uint32 {.exportc.} = glGetUniformLocationI(h, n)

proc glUniform1fI(l: uint32, v: float32) {.importwasm: "GLCtx.uniform1f(_wrtglap._nimu[l], v)".}
proc glUniform1f(l: uint32, v: float32) {.exportc.} = glUniform1fI(l, v)

proc glUniform1iI(l: uint32, v: int32) {.importwasm: "GLCtx.uniform1i(_wrtglap._nimu[l], v)".}
proc glUniform1i(l: uint32, v: int32) {.exportc.} = glUniform1iI(l, v)

proc glUniform1fvI(l: uint32, b: ptr float32, s: uint32) {.importwasm: "GLCtx.uniform1fv(_wrtglap._nimu[l], new Float32Array(_nima.buffer, b, s))".}
proc glUniform1fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform1fvI(l, v, c * 1)

proc glUniform2fvI(l: uint32, b: ptr float32, s: uint32) {.importwasm: "GLCtx.uniform2fv(_wrtglap._nimu[l], new Float32Array(_nima.buffer, b, s))".}
proc glUniform2fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform2fvI(l, v, c * 2)

proc glUniform3fvI(l: uint32, b: ptr float32, s: uint32) {.importwasm: "GLCtx.uniform3fv(_wrtglap._nimu[l], new Float32Array(_nima.buffer, b, s))".}
proc glUniform3fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform3fvI(l, v, c * 3)

proc glUniform4fvI(l: uint32, b: ptr float32, s: uint32) {.importwasm: "GLCtx.uniform4fv(_wrtglap._nimu[l], new Float32Array(_nima.buffer, b, s))".}
proc glUniform4fv(l, c: uint32, v: ptr float32) {.exportc.} = glUniform4fvI(l, v, c * 4)

proc glDrawArraysI(m, f, c: uint32) {.importwasm: "GLCtx.drawArrays(m, f, c)".}
proc glDrawArrays(m, f, c: uint32) {.exportc.} = glDrawArraysI(m, f, c)

proc glEnableI(v: uint32) {.importwasm: "GLCtx.enable(v)".}
proc glEnable(v: uint32) {.exportc.} = glEnableI(v)

proc glDisableI(v: uint32) {.importwasm: "GLCtx.disable(v)".}
proc glDisable(v: uint32) {.exportc.} = glDisableI(v)

proc glColorMaskI(r, g, b, a: bool) {.importwasm: "GLCtx.colorMask(r, g, b, a)".}
proc glColorMask(r, g, b, a: bool) {.exportc.} = glColorMaskI(r, g, b, a)

proc glDepthMaskI(f: bool) {.importwasm: "GLCtx.depthMask(f)".}
proc glDepthMask(f: bool) {.exportc.} = glDepthMaskI(f)

proc glStencilMaskI(f: uint32) {.importwasm: "GLCtx.stencilMask(f)".}
proc glStencilMask(f: uint32) {.exportc.} = glStencilMaskI(f)

proc glStencilOpI(a, b, c: uint32) {.importwasm: "GLCtx.stencilOp(a, b, c)".}
proc glStencilOp(a, b, c: uint32) {.exportc.} = glStencilOpI(a, b, c)

proc glStencilFuncI(a, b, c: uint32) {.importwasm: "GLCtx.stencilFunc(a, b, c)".}
proc glStencilFunc(a, b, c: uint32) {.exportc.} = glStencilFuncI(a, b, c)

proc glBlendColorI(r, g, b, a: float32) {.importwasm: "GLCtx.blendColor(r, g, b, a)".}
proc glBlendColor(r, g, b, a: float32) {.exportc.} = glBlendColorI(r, g, b, a)

proc glBlendFuncI(a, b: uint32) {.importwasm: "GLCtx.blendFunc(a, b)".}
proc glBlendFunc(a, b: uint32) {.exportc.} = glBlendFuncI(a, b)

proc glActiveTextureI(a: uint32) {.importwasm: "GLCtx.activeTexture(a)".}
proc glActiveTexture(a: uint32) {.exportc.} = glActiveTextureI(a)

proc glBufferDataI(t, s: uint32, d: pointer, u: uint32) {.importwasm: "GLCtx.bufferData(t, new DataView(_nima.buffer, d, s), u)".}
proc glBufferData(t, s: uint32, d: pointer, u: uint32) {.exportc.} = glBufferDataI(t, s, d, u)

proc glDrawElementsI(a, b, c, d: uint32) {.importwasm: "GLCtx.drawElements(a, b, c, d)".}
proc glDrawElements(a, b, c, d: uint32) {.exportc.} = glDrawElementsI(a, b, c, d)

# proc glTexSubImage2DI() {.importwasm: "".}
# proc glTexSubImage2D() {.exportc.} = glTexSubImage2DI()

proc glPixelStoreiI(a, b: uint32) {.importwasm: "GLCtx.pixelStorei(a, b)".}
proc glPixelStorei(a, b: uint32) {.exportc.} = glPixelStoreiI(a, b)

proc glTexImage2DUint8I(target: uint32, level, internalFormat: int32, width, height, border: int32, format, typ: uint32, sz: int32, data: pointer) {.importwasm: """
  GLCtx.texImage2D(target, level, internalFormat, width, height, border, format, typ, new Uint8Array(_nima.buffer, data, sz))
  """.}
import strutils

proc bytesInFormat(f: uint32): int32 =
  case f
  of 0x1906: # GL_ALPHA
    1
  else:
    echo "unknown format: ", toHex(f)
    assert(false, "Unknown format " & $f)
    0

proc glTexImage2D(target: uint32, level, internalFormat: int32, width, height, border: int32, format, typ: uint32, data: pointer) {.exportc.} =
  case typ
  of 0x1401: # GL_UNSIGNED_BYTE
    glTexImage2DUint8I(target, level, internalFormat, width, height, border, format, typ, width * height * bytesInFormat(format), data)
  else:
    echo "unknown typ: ", toHex(format)
    assert(false, "Unknown typ " & $format)

proc glTexSubImage2DUint8I(target: uint32, level, xoffset, yoffset: int32, width, height: int32, format, typ: uint32, sz: int32, data: pointer) {.importwasm: """
  GLCtx.texSubImage2D(target, level, xoffset, yoffset, width, height, format, typ, new Uint8Array(_nima.buffer, data, sz))
  """.}
proc glTexSubImage2D(target: uint32, level, xoffset, yoffset: int32, width, height: int32, format, typ: uint32, data: pointer) {.exportc.} =
  case typ
  of 0x1401: # GL_UNSIGNED_BYTE
    glTexSubImage2DUint8I(target, level, xoffset, yoffset, width, height, format, typ, width * height * bytesInFormat(format), data)
  else:
    echo "unknown typ: ", toHex(format)
    assert(false, "Unknown typ " & $format)


proc glBlendFuncSeparateI(a, b, c, d: uint32) {.importwasm: "GLCtx.blendFuncSeparate(a, b, c, d)".}
proc glBlendFuncSeparate(a, b, c, d: uint32) {.exportc.} = glBlendFuncSeparateI(a, b, c, d)

proc glDeleteFramebufferI(h: uint32) {.importwasm: "var p = _wrtglp[h]; delete _wrtglp[h]; GLCtx.deleteFramebuffer(p)".}
proc glDeleteFramebuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: glDeleteFramebufferI(tx[i])

proc glDeleteRenderbufferI(h: uint32) {.importwasm: "var p = _wrtglp[h]; delete _wrtglp[h]; GLCtx.deleteRenderbuffer(p)".}
proc glDeleteRenderbuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: glDeleteRenderbufferI(tx[i])

proc glCreateFramebufferI(): uint32 {.importwasm: "return _wrti(GLCtx.createFramebuffer())".}
proc glCreateFramebuffer(): uint32 {.exportc.} = glCreateFramebufferI()
proc glGenFramebuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateFramebufferI()

proc glCreateBufferI(): uint32 {.importwasm: "return _wrti(GLCtx.createBuffer())".}
proc glCreateBuffer(): uint32 {.exportc.} = glCreateBufferI()
proc glGenBuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateBufferI()

proc glBindFramebufferI(a, b: uint32) {.importwasm: "GLCtx.bindFramebuffer(a, _wrtglp[b])".}
proc glBindFramebuffer(a, b: uint32) {.exportc.} = glBindFramebufferI(a, b)

proc glCreateRenderbufferI(): uint32 {.importwasm: "return _wrti(GLCtx.createRenderbuffer())".}
proc glCreateRenderbuffer(): uint32 {.exportc.} = glCreateRenderbufferI()
proc glGenRenderbuffers(sz: uint32, tx: ptr UncheckedArray[uint32]) {.exportc.} =
  for i in 0 ..< sz: tx[i] = glCreateRenderbufferI()

proc glBindRenderbufferI(a, b: uint32) {.importwasm: "GLCtx.bindRenderbuffer(a, _wrtglp[b])".}
proc glBindRenderbuffer(a, b: uint32) {.exportc.} = glBindRenderbufferI(a, b)

# proc glRenderbufferStorageI() {.importwasm: "".}
# proc glRenderbufferStorage() {.exportc.} = glRenderbufferStorageI()

proc glFramebufferRenderbufferI(a, b, c, d: uint32) {.importwasm: "GLCtx.framebufferRenderbuffer(a, b, c, _wrtgl[d])".}
proc glFramebufferRenderbuffer(a, b, c, d: uint32) {.exportc.} = glFramebufferRenderbufferI(a, b, c, d)

# proc glFramebufferTexture2DI() {.importwasm: "".}
# proc glFramebufferTexture2D() {.exportc.} = glFramebufferTexture2DI()

proc glGetIntegervI(a: uint32, v: ptr int32) {.importwasm: """
  var o = GLCtx.getParameter(a);
  _nimwi(o['length'] == undefined ? [o] : o, v)
  """.}
proc glGetIntegerv(a: uint32, v: ptr int32) {.exportc.} = glGetIntegervI(a, v)

proc glGetBooleanvI(a: uint32): int32 {.importwasm: "return GLCtx.getParam(a)?1:0".}
proc glGetBooleanv(a: uint32, v: ptr bool) {.exportc.} = v[] = glGetBooleanvI(a) != 0

proc glGetFloatvI(a: uint32, v: ptr float32) {.importwasm: """
  var o = GLCtx.getParameter(a);
  _nimwf(o['length'] == undefined ? [o] : o, v)
  """.}
proc glGetFloatv(a: uint32, v: ptr float32) {.exportc.} = glGetFloatvI(a, v)

proc glViewportI(a, b, c, d: uint32) {.importwasm: "GLCtx.viewport(a, b, c, d)".}
proc glViewport(a, b, c, d: uint32) {.exportc.} = glViewportI(a, b, c, d)

proc glGetInfoLogI(p: int32, s: uint32, m: int32, l: ptr int32, i: ptr char) {.importwasm:"""
  var s = _wrtglp[s], o = p?GLCtx.getShaderInfoLog(s):GLCtx.getProgramInfoLog(s);
  if (l) _nimwi([o.length], l);
  if (i) _nimws(o, i, m);
  """.}
proc glGetShaderInfoLog(s: uint32, maxLength: int32, length: ptr int32, infoLog: ptr char) {.exportc.} =
  glGetInfoLogI(1, s, maxLength, length, infoLog)
proc glGetProgramInfoLog(s: uint32, maxLength: int32, length: ptr int32, infoLog: ptr char) {.exportc.} =
  glGetInfoLogI(0, s, maxLength, length, infoLog)

wasmrtInitGl()
