
#ifndef __LUA_EXTRA_H_
#define __LUA_EXTRA_H_

#if defined(_USRDLL)
    #define QUICK_EXTENSIONS_DLL     __declspec(dllexport)
#else         /* use a DLL library */
    #define QUICK_EXTENSIONS_DLL
#endif

#if __cplusplus
extern "C" {
#endif

#include "lauxlib.h"

void QUICK_EXTENSIONS_DLL luaopen_quick_extensions(lua_State *L);
    
#if __cplusplus
}
#endif

#endif /* __LUA_EXTRA_H_ */
