import posix, strutils, os

import ../wasmrt

const
  builtinsPath = currentSourcePath.rsplit({DirSep, AltSep}, 1)[0] &
    "/llvm-builtins/builtins/"

template c(s: string) =
  {.compile: builtinsPath & s.}

# TODO: Extend the following list as needed
c "multi3.c"
c "lshrti3.c"
c "ashrti3.c"

proc gettimeImpl(): cint {.importwasmf: "Date.now".}

proc clock_gettime(clkId: Clockid, tp: var Timespec): cint {.exportc.} =
  let t = gettimeImpl()
  tp.tv_sec = Time(t div 1000)
  tp.tv_nsec = (t mod 1000) * 1000000

proc atan2Aux(a, b: float): float {.importwasmf: "Math.atan2".}
proc atan2(a, b: cdouble): cdouble {.exportc.} = atan2Aux(a, b)
proc atan2f(a, b: cfloat): cfloat {.exportc.} = atan2Aux(a, b)

proc cosAux(a: float): float {.importwasmf: "Math.cos".}
proc cos(a: cdouble): cdouble {.exportc.} = cosAux(a)
proc cosf(a: cfloat): cfloat {.exportc.} = cosAux(a)

proc sinAux(a: float): float {.importwasmf: "Math.sin".}
proc sin(a: cdouble): cdouble {.exportc.} = sinAux(a)
proc sinf(a: cfloat): cfloat {.exportc.} = sinAux(a)

proc powAux(a, b: float): float {.importwasmf: "Math.pow".}
proc pow(a, b: cdouble): cdouble {.exportc.} = powAux(a, b)
proc powf(a, b: cfloat): cfloat {.exportc.} = powAux(a, b)

proc parseFloat(s: cstring): cdouble {.importwasmf.}

proc strtod(s: cstring, endptr: ptr cstring): cdouble {.exportc.} =
  assert(endptr == nil, "wasmrt.strtod doesn't support endptr argument")
  parseFloat(s)

{.emit: """
int stdout = 0;
int stderr = 1;
static int dummyErrno = 0;

N_LIB_PRIVATE void* memcpy(void* a, const void* b, size_t s) {
  char* aa = (char*)a;
  char* bb = (char*)b;
  while(s) {
    --s;
    *aa = *bb;
    ++aa;
    ++bb;
  }
  return a;
}

N_LIB_PRIVATE void* memmove(void *dest, const void *src, size_t len) { /* Copied from https://code.woboq.org/gcc/libgcc/memmove.c.html */
  char *d = dest;
  const char *s = src;
  if (d < s)
    while (len--)
      *d++ = *s++;
  else {
    char *lasts = s + (len-1);
    char *lastd = d + (len-1);
    while (len--)
      *lastd-- = *lasts--;
  }
  return dest;
}

N_LIB_PRIVATE void* memchr(register const void* src_void, int c, size_t length) { /* Copied from https://code.woboq.org/gcc/libiberty/memchr.c.html */
  const unsigned char *src = (const unsigned char *)src_void;

  while (length-- > 0) {
    if (*src == c)
     return (void*)src;
    src++;
  }
  return NULL;
}

N_LIB_PRIVATE int memcmp(const void* a, const void* b, size_t s) {
  char* aa = (char*)a;
  char* bb = (char*)b;
  if (aa == bb) return 0;

  while(s) {
    --s;
    int ia = *aa;
    int ib = *bb;
    int r = ia - ib; // TODO: The result might be inverted. Verify against C standard.
    if (r) return r;
    *aa = *bb;
    ++aa;
    ++bb;
  }
  return 0;
}

N_LIB_PRIVATE void* memmem(const void *l, size_t l_len, const void *s, size_t s_len) {
  register char *cur, *last;
  const char *cl = (const char *)l;
  const char *cs = (const char *)s;

  /* we need something to compare */
  if (l_len == 0 || s_len == 0)
    return NULL;

  /* "s" must be smaller or equal to "l" */
  if (l_len < s_len)
    return NULL;

  /* special case where s_len == 1 */
  if (s_len == 1)
    return memchr(l, (int)*cs, l_len);

  /* the last position where its possible to find "s" in "l" */
  last = (char *)cl + l_len - s_len;

  for (cur = (char *)cl; cur <= last; cur++)
    if (cur[0] == cs[0] && memcmp(cur, cs, s_len) == 0)
      return cur;

  return NULL;
}

N_LIB_PRIVATE void* memset(void* a, int b, size_t s) {
  char* aa = (char*)a;
  while(s) {
    --s;
    *aa = b;
    ++aa;
  }
  return a;
}

N_LIB_PRIVATE size_t strlen(const char* a) {
  const char* b = a;
  while (*b++);
  return b - a - 1;
}

N_LIB_PRIVATE int strcmp(const char *s1, const char *s2) {
  while (*s1 && (*s1 == *s2)) {
    s1++;
    s2++;
  }
  return *(unsigned char *)s1 - *(unsigned char *)s2;
}

N_LIB_PRIVATE char* strerror(int errnum) {
  return "strerror is not supported";
}

N_LIB_PRIVATE int* __errno_location() {
  return &dummyErrno;
}

N_LIB_PRIVATE char* strstr(const char *haystack, const char *needle) {
  if (haystack == NULL || needle == NULL) {
    return NULL;
  }

  for ( ; *haystack; haystack++) {
    // Is the needle at this point in the haystack?
    const char *h, *n;
    for (h = haystack, n = needle; *h && *n && (*h == *n); ++h, ++n) {
      // Match is progressing
    }
    if (*n == '\0') {
      // Found match!
      return haystack;
    }
    // Didn't match here.  Try again further along haystack.
  }
  return NULL;
}

N_LIB_PRIVATE double trunc(double x) {
  if (x >= 0.0) {
    return (double)((int)x);
  } else {
    return -((double)((int)-x));
  }
}

N_LIB_PRIVATE double fmod(double x, double y) {
  return x - trunc(x / y) * y;
}

N_LIB_PRIVATE float fmodf(float x, float y) {
  return fmod(x, y);
}

""".}
