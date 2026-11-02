# WebAssembly (wasm32), static, release only, with pthreads and wasm SIMD.
# Emscripten comes from EMSDK (set VCPKG_KEEP_ENV_VARS=EMSDK when running vcpkg).
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED EMSCRIPTEN_ROOT EMSDK EM_CONFIG PATH)

set(VCPKG_TARGET_ARCHITECTURE wasm32)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Emscripten)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${VCPKG_ROOT_DIR}/scripts/toolchains/emscripten.cmake")
set(VCPKG_BUILD_TYPE release)

# The application links with -sUSE_PTHREADS=1, so every port is built with -pthread.
# -msimd128 turns on SIMD128; -msse2/-msse4.1 make clang define __SSE2__/__SSE4_1__ so libwebp's
# *_sse2.c/*_sse41.c compile to real code.
set(VCPKG_C_FLAGS "-pthread -msimd128 -msse2 -msse4.1")
set(VCPKG_CXX_FLAGS "-pthread -msimd128 -msse2 -msse4.1")
set(VCPKG_LINKER_FLAGS "-pthread")

# libwebp 1.6.0's cmake/cpu.cmake detects only SSE4.1 on Emscripten; state that SSE2 is there too.
if(PORT STREQUAL "libwebp")
    string(APPEND VCPKG_C_FLAGS " -DWEBP_HAVE_SSE2=1")
endif()
