
const EOF = 0

type
  Ctx = object
    output: string
    input: string
    inputCursor: int
    the_a: cint
    the_b: cint
    look_ahead: cint
    the_x: cint
    the_y: cint

proc error(s: string) =
  raise newException(ValueError, s)

# /* is_alphanum -- return true if the character is a letter, digit, underscore,
#         dollar sign, or non-ASCII character.
# */



proc is_alphanum(codeunit: cint): bool =
    return (
        (codeunit >= 'a'.ord and codeunit <= 'z'.ord) or
        (codeunit >= '0'.ord and codeunit <= '9'.ord) or (codeunit >= 'A'.ord and codeunit <= 'Z'.ord) or codeunit == '_'.ord or codeunit == '$'.ord or codeunit == '\\'.ord or codeunit > 126
    );


# /* get -- return the next character from stdin. Watch out for lookahead. If
#         the character is a control character, translate it to a space or
#         linefeed.
# */

proc getc(ctx: var Ctx): cint =
  if ctx.inputCursor == ctx.input.len: return EOF
  result = ctx.input[ctx.inputCursor].cint
  inc ctx.inputCursor

  # var s: array[1, char]
  # if f.readChars(s, 0, 1) == 0:
  #   return EOF
  # else:
  #   return s[0].ord.cint


proc putc(ctx: var Ctx, c: cint) =
  var c = c
  if c == '\n'.ord:
    c = ' '.ord
  ctx.output &= c.char

proc get(ctx: var Ctx): cint =
    var codeunit = ctx.look_ahead;
    ctx.look_ahead = EOF;
    if (codeunit == EOF):
        codeunit = ctx.getc();

    if (codeunit >= ' '.ord or codeunit == '\n'.ord or codeunit == EOF):
        return codeunit;

    if (codeunit == '\r'.ord):
        return '\n'.ord;
    return ' '.ord;

# /* peek -- get the next character without advancing.
# */

proc peek(ctx: var Ctx): cint =
    ctx.look_ahead = ctx.get();
    return ctx.look_ahead;

# /* next -- get the next character, excluding comments. peek() is used to see
#         if a '/' is followed by a '/' or '*'.
# */

proc next(ctx: var Ctx): cint =
    var codeunit = ctx.get();
    if  (codeunit == '/'.ord):
        case ctx.peek().char
        of '/':
            while true:
                codeunit = ctx.get();
                if (codeunit <= '\n'.ord):
                    break;

        of '*':
            discard ctx.get();
            while (codeunit != ' '.ord):
                case ctx.get()
                of '*'.ord:
                    if (ctx.peek() == '/'.ord):
                        discard ctx.get();
                        codeunit = ' '.ord;

                of EOF:
                    error("Unterminated comment.");
                else: discard

        else: discard
    ctx.the_y = ctx.the_x;
    ctx.the_x = codeunit;
    return codeunit;


# /* action -- do something! What you do is determined by the argument:
#         1   Output A. Copy B to A. Get the next B.
#         2   Copy B to A. Get the next B. (Delete A).
#         3   Get the next B. (Delete B).
#    action treats a string as a single character.
#    action recognizes a regular expression if it is preceded by the likes of
#    '(' or ',' or '='.
# */

proc `==`(cp: int, c: char): bool = cp == c.ord

proc action(ctx: var Ctx, determined: cint) =
    if determined <= 1:
        ctx.putc(ctx.the_a);
        if (
            (ctx.the_y == '\n'.ord or ctx.the_y == ' '.ord) and
            (ctx.the_a == '+'.ord or ctx.the_a == '-'.ord or ctx.the_a == '*'.ord or ctx.the_a == '/'.ord) and
            (ctx.the_b == '+'.ord or ctx.the_b == '-'.ord or ctx.the_b == '*'.ord or ctx.the_b == '/'.ord)
        ):
            ctx.putc(ctx.the_y);

    if determined <= 2:
        ctx.the_a = ctx.the_b;
        if (ctx.the_a == '\'' or ctx.the_a == '"' or ctx.the_a == '`'):
            while true:
                ctx.putc(ctx.the_a);
                ctx.the_a = ctx.get();
                if (ctx.the_a == ctx.the_b):
                    break;
                if (ctx.the_a == '\\'):
                    ctx.putc(ctx.the_a);
                    ctx.the_a = ctx.get();
                if (ctx.the_a == EOF):
                    error("Unterminated string literal.");
    if determined <= 3:
        ctx.the_b = ctx.next();
        if (ctx.the_b == '/' and (
            ctx.the_a == '(' or ctx.the_a == ',' or ctx.the_a == '=' or ctx.the_a == ':' or
            ctx.the_a == '[' or ctx.the_a == '!' or ctx.the_a == '&' or ctx.the_a == '|' or
            ctx.the_a == '?' or ctx.the_a == '+' or ctx.the_a == '-' or ctx.the_a == '~' or
            ctx.the_a == '*' or ctx.the_a == '/' or ctx.the_a == '{' or ctx.the_a == '}' or
            ctx.the_a == ';'
        )):
            ctx.putc(ctx.the_a);
            if (ctx.the_a == '/' or ctx.the_a == '*'):
                ctx.putc(' '.ord);
            ctx.putc(ctx.the_b);
            while true:
                ctx.the_a = ctx.get();
                if (ctx.the_a == '['):
                    while true:
                        ctx.putc(ctx.the_a);
                        ctx.the_a = ctx.get();
                        if (ctx.the_a == ']'):
                            break;

                        if (ctx.the_a == '\\'):
                            ctx.putc(ctx.the_a);
                            ctx.the_a = ctx.get();

                        if (ctx.the_a == EOF):
                            error(
                                "Unterminated set in Regular Expression literal."
                            );

                elif (ctx.the_a == '/'):
                    case (ctx.peek().char)
                    of '/', '*':
                        error(
                            "Unterminated set in Regular Expression literal."
                        );
                    else: discard

                elif (ctx.the_a == '\\'):
                    ctx.putc(ctx.the_a);
                    ctx.the_a = ctx.get();

                if (ctx.the_a == EOF):
                    error("Unterminated Regular Expression literal.");

                ctx.putc(ctx.the_a);

            ctx.the_b = ctx.next();

# /* jsmin -- Copy the input to the output, deleting the characters which are
#         insignificant to JavaScript. Comments will be removed. Tabs will be
#         replaced with spaces. Carriage returns will be replaced with linefeeds.
#         Most spaces and linefeeds will be removed.
# */

proc jsminAux(ctx: var Ctx) =
    if (ctx.peek() == 0xEF):
        discard ctx.get();
        discard ctx.get();
        discard ctx.get();

    ctx.the_a = ctx.get();
    ctx.action(3);
    while (ctx.the_a != EOF):
        case (ctx.the_a)
        of ' '.ord:
            ctx.action(
                if is_alphanum(ctx.the_b): 1 else: 2
            );
        of '\n'.ord:
            case ctx.the_b.char
            of '{', '[', '(', '+', '-', '!', '~':
                ctx.action(1);
            of ' ':
                ctx.action(3);
            else:
                ctx.action(
                    if is_alphanum(ctx.the_b): 1 else: 2
                );
        else:
            case ctx.the_b.char
            of ' ':
                ctx.action(
                    if is_alphanum(ctx.the_a): 1 else: 3
                );
            of '\n':
                case ctx.the_a.char
                of '}', ']', ')', '+', '-', '"', '\'', '`':
                    ctx.action(1);
                else:
                    ctx.action(
                        if is_alphanum(ctx.the_a): 1 else: 3
                    );
            else:
                ctx.action(1);

# /* main -- Output any command line arguments as comments
#         and then minify the input.
# */

proc minifyJs*(s: string): string =
  var ctx: Ctx
  ctx.input = s
  ctx.jsminAux()
  result = ctx.output


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
  echo minifyJs("""function foo() {
  // This is some comment
  alert(" Hello this is a string!\\n ");
  return a + b;
  }

  """)

  echo minifyJs("""function foo() {
  // This is some comment
  alert(" Hello this is a string!\\n ");
  return a +
b
;
  }

  """)

  let r = minifyJs "function foo(){alert(\" Hello this is a string! \");return a+b;}"
  echo r

  proc cmpStr(a, b: string) =
    var sz = min(a.len, b.len)
    for i in 0 ..< sz:
      if a[i] != b[i]:
        raise newException(ValueError, "Strings not equal. Char idx: " & $i & " a: " & a[i] & ", b: " & b[i])
    if b.len > a.len:
      raise newException(ValueError, "Strings not equal. B is longer.")
    if a.len > b.len:
      raise newException(ValueError, "Strings not equal. A is longer.")

  cmpStr(r, "function foo(){alert(\" Hello this is a string! \");return a+b;}")
