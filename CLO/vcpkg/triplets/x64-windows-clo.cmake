# Windows x64: static libraries, dynamic CRT (/MD and /MDd), MSVC toolset 14.38.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_PLATFORM_TOOLSET v143)
set(VCPKG_PLATFORM_TOOLSET_VERSION 14.38)

# LibRaw without LCMS: the application links its own Little-CMS, and the LibRawLite bundled with
# FreeImage 3.18.0 was built without LCMS too.
if(PORT STREQUAL "libraw")
    list(APPEND VCPKG_CMAKE_CONFIGURE_OPTIONS -DENABLE_LCMS=OFF)
endif()

# vcpkg's scripts/toolchains/windows.cmake without /Z7 (no debug information in the static libraries).
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/toolchains/windows-noz7.cmake")
# A chainloaded toolchain makes vcpkg skip vcvars; load it anyway so the pinned 14.38 toolset is used.
set(VCPKG_LOAD_VCVARS_ENV ON)
