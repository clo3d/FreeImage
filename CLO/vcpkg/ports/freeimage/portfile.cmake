vcpkg_from_sourceforge(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO freeimage/Source%20Distribution
    REF 3.18.0
    FILENAME "FreeImage3180.zip"
    SHA512 9d9cc7e2d57552c3115e277aeb036e0455204d389026b17a3f513da5be1fd595421655488bb1ec2f76faebed66049119ca55e26e2a6d37024b3fb7ef36ad4818
    PATCHES
        disable-plugins-depending-on-internal-third-party-libraries.patch
        use-external-jpeg.patch
        use-external-jxrlib.patch
        use-external-libtiff.patch
        use-external-openjpeg.patch
        use-external-png-zlib.patch
        use-external-rawlib.patch
        use-external-webp.patch
        use-external-openexr.patch
        use-freeimage-config-include.patch
        fix-function-overload.patch
        use-typedef-as-already-declared.patch
        use-functions-to-override-libtiff-warning-error-handlers.patch
        remove_auto_ptr.patch
        rawlib-build-fix.patch
        typedef-xcode.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
          "${CMAKE_CURRENT_LIST_DIR}/FreeImageConfig-static.h"
          "${CMAKE_CURRENT_LIST_DIR}/FreeImageConfig-dynamic.h" 
    DESTINATION "${SOURCE_PATH}"
)

# This is not strictly necessary, but to make sure
# that no "internal" libraries are used we remove them
file(REMOVE_RECURSE
    "${SOURCE_PATH}/Source/LibJPEG"
    "${SOURCE_PATH}/Source/LibPNG"
    "${SOURCE_PATH}/Source/LibTIFF4"
    "${SOURCE_PATH}/Source/ZLib"
    "${SOURCE_PATH}/Source/LibOpenJPEG"
    "${SOURCE_PATH}/Source/LibJXR"
    "${SOURCE_PATH}/Source/LibWebP"
    "${SOURCE_PATH}/Source/LibRawLite"
    "${SOURCE_PATH}/Source/OpenEXR"
)

# CLO: the plugins that need a library of their own are features (vcpkg.json). Each registration in
# Plugin.cpp is guarded, and CMakeLists.txt defines the guard and leaves the plugin's sources and
# library out when its feature is off, as CLO's earlier wasm build patched them out. The
# plugins after a missing one take the next ids, as after the G3 plugin above.
# CLO overlay (libwebp CVE-2023-4863 rebuild): CLO keeps FreeImage 3.18.0's own
# FreeImage.h, whose FREE_IMAGE_FORMAT values are the plugin ids in registration order (FIF_FAXG3 = 27 ...
# FIF_WEBP = 35, FIF_JXR = 36). A plugin left out (G3 always, EXR/J2K/JP2/RAW/JXR when their feature is
# off) keeps its slot with a disabled placeholder, so every id after it still matches that header.
set(_fi_plugin_G3  "G3;g3")
set(_fi_plugin_EXR "EXR;exr")
set(_fi_plugin_J2K "J2K;j2k,j2c")
set(_fi_plugin_JP2 "JP2;jp2")
set(_fi_plugin_RAW "RAW;raw")
set(_fi_plugin_JXR "JPEG-XR;jxr,wdp,hdp")
foreach(_fi_plugin IN ITEMS EXR J2K JP2 RAW JXR)
    list(GET _fi_plugin_${_fi_plugin} 0 _fi_format)
    list(GET _fi_plugin_${_fi_plugin} 1 _fi_extension)
    vcpkg_replace_string("${SOURCE_PATH}/Source/FreeImage/Plugin.cpp"
        "\t\t\ts_plugins->AddNode(Init${_fi_plugin});\n"
        "#ifndef FREEIMAGE_NO_PLUGIN_${_fi_plugin}\n\t\t\ts_plugins->AddNode(Init${_fi_plugin});\n#else\n\t\t\tAddUnavailablePlugin(s_plugins, \"${_fi_format}\", \"${_fi_extension}\");\n#endif\n")
endforeach()
list(GET _fi_plugin_G3 0 _fi_format)
list(GET _fi_plugin_G3 1 _fi_extension)
vcpkg_replace_string("${SOURCE_PATH}/Source/FreeImage/Plugin.cpp"
    "#if 0\n \t\t\ts_plugins->AddNode(InitG3);\n#endif\n"
    "\t\t\tAddUnavailablePlugin(s_plugins, \"${_fi_format}\", \"${_fi_extension}\");\n")
vcpkg_replace_string("${SOURCE_PATH}/Source/FreeImage/Plugin.cpp"
    "static PluginList *s_plugins = NULL;\n"
    "static PluginList *s_plugins = NULL;\n\n// Holds the id of a plugin this build leaves out; disabled, so lookups and loads skip it.\nstatic void DLL_CALLCONV InitUnavailable(Plugin *, int) {}\n\nstatic void AddUnavailablePlugin(PluginList *plugins, const char *format, const char *extension) {\n\tFREE_IMAGE_FORMAT fif = plugins->AddNode(InitUnavailable, NULL, format, \"Unavailable in this build\", extension, NULL);\n\tif (fif != FIF_UNKNOWN) {\n\t\tplugins->FindNodeFromFIF(fif)->m_enabled = FALSE;\n\t}\n}\n")

# CLO: on Emscripten the WebP plugin decodes on the calling thread (use_threads = 0). There libwebp's worker
# thread is a Web Worker, started per lossy WebP 512 px or wider. Other platforms keep use_threads = 1.
vcpkg_replace_string("${SOURCE_PATH}/Source/FreeImage/PluginWebP.cpp"
    "\t\t// use multi-threaded decoding\n\t\tdecoder_config.options.use_threads = 1;\n"
    "\t\t// use multi-threaded decoding\n\t\t// CLO: not on Emscripten, where the libwebp worker thread is a Web Worker; decode on the calling thread there\n#ifdef __EMSCRIPTEN__\n\t\tdecoder_config.options.use_threads = 0;\n#else\n\t\tdecoder_config.options.use_threads = 1;\n#endif\n")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        exr      FREEIMAGE_WITH_EXR
        jpeg2000 FREEIMAGE_WITH_JPEG2000
        jxr      FREEIMAGE_WITH_JXR
        raw      FREEIMAGE_WITH_RAW
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
    OPTIONS_DEBUG
        -DINSTALL_HEADERS=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

# CLO: on macOS the app defines BYTE, WORD, DWORD, LONG and BOOL itself (BOOL is the SDK's bool on
# arm64), so the installed header skips FreeImage's own typedefs there, as CLO's earlier FreeImage.h did.
# The library itself is built with them.
if(VCPKG_TARGET_IS_OSX)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/FreeImage.h"
        "#ifndef _MSC_VER\n// define portable types for 32-bit / 64-bit OS"
        "#if !defined(_MSC_VER) && !defined(__APPLE__)\n// define portable types for 32-bit / 64-bit OS")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/FreeImage.h"
        "#else\n// MS is not C99 ISO compliant"
        "#elif !defined(__APPLE__)\n// MS is not C99 ISO compliant")
endif()

vcpkg_copy_pdbs()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/license-fi.txt")
