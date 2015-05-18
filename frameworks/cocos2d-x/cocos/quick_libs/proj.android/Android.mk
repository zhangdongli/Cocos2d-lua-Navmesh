
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := quick_libs_static
LOCAL_MODULE_FILENAME := libquick_libs

LOCAL_SRC_FILES := \
    $(LOCAL_PATH)/../package_quick_register.cpp

LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/.. 

LOCAL_C_INCLUDES := $(LOCAL_EXPORT_C_INCLUDES) \
                    $(LOCAL_PATH)/../../../frameworks/cocos2d-x/cocos \
                    $(LOCAL_PATH)/../../../frameworks/cocos2d-x/external/lua/luajit/include  \
                    $(LOCAL_PATH)/../../../frameworks/cocos2d-x/external/lua/tolua \
                    $(LOCAL_PATH)/../../../frameworks/cocos2d-x/external \
                    $(LOCAL_PATH)/../../../frameworks/cocos2d-x/cocos/scripting/lua-bindings/manual

LOCAL_STATIC_LIBRARIES := extra_static
LOCAL_STATIC_LIBRARIES += quick_extensions_static
LOCAL_STATIC_LIBRARIES += cocos2d_lua_static

include $(BUILD_STATIC_LIBRARY)

$(call import-module,src/extra)
$(call import-module,src/extensions)
$(call import-module,scripting/lua-bindings/proj.android)
