import std/strutils

const EOF = '\0'

type
  Ctx = object
    output: string
    input: string
    inputCursor: int
    the_a: char
    the_b: char
    look_ahead: char
    the_x: char
    the_y: char

proc error(s: string) =
  raise newException(ValueError, s)

proc is_alphanum(codeunit: char): bool =
  # return true if the character is a letter, digit, underscore,
  # dollar sign, or non-ASCII character.
  (codeunit >= 'a' and codeunit <= 'z') or
  (codeunit >= '0' and codeunit <= '9') or
  (codeunit >= 'A' and codeunit <= 'Z') or
  codeunit == '_' or codeunit == '$' or codeunit == '\\' or
  codeunit.ord > 126

proc getc(ctx: var Ctx): char =
  if ctx.inputCursor == ctx.input.len: return EOF
  result = ctx.input[ctx.inputCursor]
  inc ctx.inputCursor

proc putc(ctx: var Ctx, c: char) =
  var c = c
  if c == '\n':
    c = ' '
  ctx.output &= c

proc get(ctx: var Ctx): char =
  # return the next character from stdin. Watch out for lookahead. If
  # the character is a control character, translate it to a space or
  # linefeed.
  var codeunit = ctx.look_ahead
  ctx.look_ahead = EOF
  if codeunit == EOF:
    codeunit = ctx.getc()

  if codeunit >= ' ' or codeunit == '\n' or codeunit == EOF:
    return codeunit

  if codeunit == '\r':
    return '\n'
  return ' '

proc peek(ctx: var Ctx): char =
  # get the next character without advancing.
  ctx.look_ahead = ctx.get()
  return ctx.look_ahead

proc next(ctx: var Ctx): char =
  # get the next character, excluding comments. peek() is used to see
  # if a '/' is followed by a '/' or '*'.
  var codeunit = ctx.get()
  if codeunit == '/':
    case ctx.peek()
    of '/':
      while true:
        codeunit = ctx.get()
        if codeunit <= '\n':
          break

    of '*':
      discard ctx.get()
      while codeunit != ' ':
        case ctx.get()
        of '*':
          if ctx.peek() == '/':
            discard ctx.get()
            codeunit = ' '

        of EOF:
          error("Unterminated comment.")
        else: discard

    else: discard
  ctx.the_y = ctx.the_x
  ctx.the_x = codeunit
  return codeunit

proc action(ctx: var Ctx, determined: int) =
  # do something! What you do is determined by the argument:
  #    1   Output A. Copy B to A. Get the next B.
  #    2   Copy B to A. Get the next B. (Delete A).
  #    3   Get the next B. (Delete B).
  # action treats a string as a single character.
  # action recognizes a regular expression if it is preceded by the likes of
  # '(' or ',' or '='.
  if determined <= 1:
    ctx.putc(ctx.the_a)
    if ctx.the_y in ['\n', ' '] and
        ctx.the_a in ['+', '-', '*', '/'] and
        ctx.the_b in ['+', '-', '*', '/']:
      ctx.putc(ctx.the_y)

  if determined <= 2:
    ctx.the_a = ctx.the_b
    if ctx.the_a in ['\'', '"', '`']:
      while true:
        ctx.putc(ctx.the_a)
        ctx.the_a = ctx.get()
        if ctx.the_a == ctx.the_b:
          break
        if ctx.the_a == '\\':
          ctx.putc(ctx.the_a)
          ctx.the_a = ctx.get()
        if ctx.the_a == EOF:
          error("Unterminated string literal.")
  if determined <= 3:
    ctx.the_b = ctx.next()
    if ctx.the_b == '/' and
      ctx.the_a in ['(', ',', '=', ':',
                    '[', '!', '&', '|',
                    '?', '+', '-', '~',
                    '*', '/', '{', '}',
                    ';']:
      ctx.putc(ctx.the_a)
      if ctx.the_a in ['/', '*']:
        ctx.putc(' ')
      ctx.putc(ctx.the_b)
      while true:
        ctx.the_a = ctx.get()
        if ctx.the_a == '[':
          while true:
            ctx.putc(ctx.the_a)
            ctx.the_a = ctx.get()
            if ctx.the_a == ']':
              break

            if ctx.the_a == '\\':
              ctx.putc(ctx.the_a)
              ctx.the_a = ctx.get()

            if ctx.the_a == EOF:
              error("Unterminated set in Regular Expression literal.")

        elif ctx.the_a == '/':
          case ctx.peek()
          of '/', '*':
            error("Unterminated set in Regular Expression literal.")
          else: discard
          break

        elif ctx.the_a == '\\':
          ctx.putc(ctx.the_a)
          ctx.the_a = ctx.get()

        if ctx.the_a == EOF:
          error("Unterminated Regular Expression literal.")

        ctx.putc(ctx.the_a)

      ctx.the_b = ctx.next()

proc jsminAux(ctx: var Ctx) =
  # Copy the input to the output, deleting the characters which are
  # insignificant to JavaScript. Comments will be removed. Tabs will be
  # replaced with spaces. Carriage returns will be replaced with linefeeds.
  # Most spaces and linefeeds will be removed.
  if ctx.peek().ord == 0xEF:
    discard ctx.get()
    discard ctx.get()
    discard ctx.get()

  ctx.the_a = '\n'
  ctx.action(3)
  while ctx.the_a != EOF:
    case ctx.the_a
    of ' ':
      ctx.action(
        if is_alphanum(ctx.the_b): 1 else: 2
      )
    of '\n':
      case ctx.the_b
      of '{', '[', '(', '+', '-', '!', '~':
        ctx.action(1)
      of ' ':
        ctx.action(3)
      else:
        ctx.action(
          if is_alphanum(ctx.the_b): 1 else: 2
        )
    else:
      case ctx.the_b
      of ' ':
        ctx.action(
          if is_alphanum(ctx.the_a): 1 else: 3
        )
      of '\n':
        case ctx.the_a
        of '}', ']', ')', '+', '-', '"', '\'', '`':
          ctx.action(3)
        else:
          ctx.action(
            if is_alphanum(ctx.the_a): 1 else: 3
          )
      else:
        ctx.action(1)

proc minifyJs*(s: string): string =
  var ctx: Ctx
  ctx.input = s
  ctx.jsminAux()
  strip(ctx.output)

proc escapeJs*(s: string, escapeDollarWith = "$"): string {.compileTime.} =
  result = ""
  for c in s:
    case c
    of '\a': result.add "\\a" # \x07
    of '\b': result.add "\\b" # \x08
    of '\t': result.add "\\t" # \x09
    of '\L': result.add "\\n" # \x0A
    of '\r': result.add "\\r" # \x0A
    of '\v': result.add "\\v" # \x0B
    of '\f': result.add "\\f" # \x0C
    of '\e': result.add "\\e" # \x1B
    of '\\': result.add("\\\\")
    of '\'': result.add("\\'")
    of '\"': result.add("\\\"")
    of '$': result.add(escapeDollarWith)
    else: result.add(c)

when isMainModule:
  proc cmpStr(a, b: string) =
    var sz = min(a.len, b.len)
    for i in 0 ..< sz:
      if a[i] != b[i]:
        raise newException(ValueError, "Strings not equal. Char idx: " & $i & " a: " & a[i] & ", b: " & b[i])
    if b.len > a.len:
      raise newException(ValueError, "Strings not equal. B is longer.")
    if a.len > b.len:
      raise newException(ValueError, "Strings not equal. A is longer.")

  template t(a, b: string) =
    # echo minifyJs(a)
    cmpStr(minifyJs(a), b)

  t("""function foo() {
  // This is some comment
  alert(" Hello this is a string!\\n ");
  return a + b;
  }

""", """function foo(){alert(" Hello this is a string!\\n ");return a+b;}""")

  t("""
function foo() {
  // This is some comment
  alert(" Hello this is a string!\\n ");
  return a +
b
;
  }

""", """function foo(){alert(" Hello this is a string!\\n ");return a+b;}""")

  t("function foo(){alert(\" Hello this is a string! \");return a+b;}",
    "function foo(){alert(\" Hello this is a string! \");return a+b;}")

  t("""
const regex = /^\d+$/;
const str = "12345";
console.log(regex.test(str)); // true
""", """const regex=/^\d+$/;const str="12345";console.log(regex.test(str));""")

  t("'BLA'", "'BLA'")
  t("""o =
    b(a,
      1 +
      2)""", "o=b(a,1+2)")
