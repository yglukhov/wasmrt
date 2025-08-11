#ifndef _NIM_WASMRT_ALLTYPES_H_
#define _NIM_WASMRT_ALLTYPES_H_

#define TYPEDEF typedef
#define STRUCT struct
#include "../../arch/arm/bits/alltypes.h.in"
#include "../../include/alltypes.h.in"
#undef TYPEDEF
#undef STRUCT

#endif // _NIM_WASMRT_ALLTYPES_H_
