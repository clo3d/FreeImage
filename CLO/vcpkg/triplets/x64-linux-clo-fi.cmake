# Linux x64: static, -fPIC (vcpkg's Linux toolchain), release only.
# Built on Rocky Linux 9 with its system GCC 11 (glibc 2.34).
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_BUILD_TYPE release)

# LibRaw without LCMS: the application links its own Little-CMS.
if(PORT STREQUAL "libraw")
    list(APPEND VCPKG_CMAKE_CONFIGURE_OPTIONS -DENABLE_LCMS=OFF)
endif()
