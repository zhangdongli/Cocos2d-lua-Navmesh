#include "luabinding/cocos2dx_extra_luabinding.h"
#include "luabinding/lua_cocos2dx_extension_filter_auto.hpp"
#include "luabinding/lua_cocos2dx_extension_nanovg_auto.hpp"
#include "luabinding/lua_cocos2dx_extension_nanovg_manual.hpp"
#include "luabinding/HelperFunc_luabinding.h"
#include "quick_extensions.h"
#include "lua/quick/lua_cocos2dx_quick_manual.hpp"
#include "CCLuaEngine.h"


void package_quick_register()
{
    auto engine = LuaEngine::getInstance();
    lua_State* L = engine->getLuaStack()->getLuaState();
    luaopen_quick_extensions(L);
    
    lua_getglobal(L, "_G");
    if (lua_istable(L, -1))//stack:...,_G,
    {
        register_all_quick_manual(L);
        luaopen_cocos2dx_extra_luabinding(L);
        register_all_cocos2dx_extension_filter(L);
        register_all_cocos2dx_extension_nanovg(L);
        register_all_cocos2dx_extension_nanovg_manual(L);
        luaopen_HelperFunc_luabinding(L);
    }
    lua_pop(L, 1);
}

