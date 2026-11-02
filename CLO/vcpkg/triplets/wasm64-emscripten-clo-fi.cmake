# WebAssembly with 64-bit memory (wasm64). As wasm32-emscripten-clo-fi.cmake, plus -sMEMORY64=1 on every
# object. vcpkg knows no wasm64 architecture; the pointer size comes from -sMEMORY64=1.
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED EMSCRIPTEN_ROOT EMSDK EM_CONFIG PATH)

set(VCPKG_TARGET_ARCHITECTURE wasm32)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Emscripten)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${VCPKG_ROOT_DIR}/scripts/toolchains/emscripten.cmake")
set(VCPKG_BUILD_TYPE release)

set(VCPKG_C_FLAGS "-pthread -sMEMORY64=1 -msimd128 -msse2 -msse4.1")
set(VCPKG_CXX_FLAGS "-pthread -sMEMORY64=1 -msimd128 -msse2 -msse4.1")
set(VCPKG_LINKER_FLAGS "-pthread -sMEMORY64=1 -sWASM_BIGINT")

if(PORT STREQUAL "libwebp")
    string(APPEND VCPKG_C_FLAGS " -DWEBP_HAVE_SSE2=1")
endif()
