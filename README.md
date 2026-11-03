# FreeImage (CLO modified)

CLO Virtual Fashion's modified FreeImage 3.18.0, as built into CLO products. Published to make the
modified source available under the FreeImage Public License (FIPL), `license-fi.txt`.

FreeImage is dual-licensed (FIPL, GPL v2, GPL v3). CLO uses and distributes it under the FreeImage Public License
(FIPL) only; `license-gplv2.txt` and `license-gplv3.txt` are kept unchanged from the original distribution.

FreeImage's own README is `README.FreeImage.md` (renamed from `README.md` so this file is the repository's front page).

## Specs
- Original: FreeImage 3.18.0, `FreeImage3180.zip` (https://sourceforge.net/projects/freeimage/files/Source%20Distribution/3.18.0/)
- Original SHA512: `9d9cc7e2d57552c3115e277aeb036e0455204d389026b17a3f513da5be1fd595421655488bb1ec2f76faebed66049119ca55e26e2a6d37024b3fb7ef36ad4818`
- Built with vcpkg (freeimage port 3.18.0, port-version 27, with a CLO overlay) for Windows x64, macOS (arm64/x64), Linux x64 and WebAssembly.
- `FreeImage-3.18.0-clo.patch` is the whole change from the original as one diff (18 files, +418/-98), except the removed directories listed below.

## Changes (2026-10-13, libwebp CVE-2023-4863 rebuild)
1. **vcpkg freeimage port patches (16):** use the external libjpeg-turbo, libpng, zlib, libtiff, libwebp,
   OpenJPEG, jxrlib, LibRaw and OpenEXR instead of the bundled copies, and build fixes.
2. **Build system:** vcpkg's `CMakeLists.txt` and `FreeImageConfig-{static,dynamic}.h` added. In CLO's
   version, EXR, J2K/JP2, JXR and RAW are optional features.
3. **Bundled libraries removed** (not built, not in the diff): `Source/LibJPEG`, `LibPNG`, `LibTIFF4`, `ZLib`,
   `LibOpenJPEG`, `LibJXR`, `LibWebP`, `LibRawLite`, `OpenEXR`.
4. **CLO, `Source/FreeImage/Plugin.cpp`:** EXR, J2K, JP2, RAW and JXR are registered only when
   `FREEIMAGE_NO_PLUGIN_<name>` is not defined. A plugin left out (G3 always) keeps its id with a disabled
   placeholder, so every `FREE_IMAGE_FORMAT` value still matches FreeImage 3.18.0's `FreeImage.h`.
   Windows, macOS and Linux build all five; the WebAssembly builds leave all five out.
5. **CLO, `CLO/so_init.cpp` (macOS and Linux):** the static build leaves out `FreeImage.cpp`'s load-time
   `FreeImage_SO_Initialise`/`FreeImage_SO_DeInitialise` (it is only compiled without `FREEIMAGE_LIB`), and the
   app relies on it there. This file restores the same constructor/destructor: it is linked into the macOS
   dylib, and on Linux merged into the archive's `Plugin.cpp.o`.
6. **CLO, the header the app compiles against, `CLO/include/FreeImage.h`:** FreeImage 3.18.0's
   `Source/FreeImage.h` with three changes (the library itself is built with `Source/FreeImage.h` in this tree,
   as the vcpkg patches leave it):
   - on macOS it skips FreeImage's own `BYTE`/`WORD`/`DWORD`/`LONG`/`BOOL` typedefs, because the app defines
     them itself;
   - the `FreeImage_JPEGTransform*`/`FreeImage_JPEGCrop*` declarations are under `#if 0`: these builds leave
     out `FreeImageToolkit/JPEGTransform.cpp`, which needs FreeImage's private libjpeg;
   - saved as UTF-8 (the original has one Latin-1 character in a comment).

## Files added by CLO
- `README.md` (this file); FreeImage's original `README.md` is kept unchanged as `README.FreeImage.md`.
- `FreeImage-3.18.0-clo.patch`: see Specs.
- `CLO/so_init.cpp`, `CLO/include/FreeImage.h`: see changes 5 and 6.
- `CLO/vcpkg/ports/freeimage/`: the vcpkg overlay port the binaries were built with (vcpkg's freeimage port
  3.18.0#27 with changes 2 and 4). It applies the 16 patches and the `Plugin.cpp` change to the original zip,
  so building it reproduces the source tree above.
- `CLO/vcpkg/triplets/`: the vcpkg triplets for each platform.
- `CLO/macos/exports.txt`: the symbols the macOS dylib exports.

## How it was built
All platforms use vcpkg at upstream commit `07f4812200df` (microsoft/vcpkg, 2026-09-27), with the overlay port
and triplets from `CLO/vcpkg`. The other ports (libwebp 1.6.0, libjpeg-turbo, libpng, zlib, libtiff, OpenJPEG,
jxrlib, LibRaw 0.22.2, OpenEXR, Imath, OpenJPH, libdeflate, liblzma, ...) are upstream's at that commit.
The shipped binaries were built with CLO's internal vcpkg, with the same freeimage overlay port and equivalent
triplets (those in `CLO/vcpkg/triplets` are CLO's triplets written out in full, without their settings for
unrelated ports); upstream `07f4812200df` with the files here reproduces them.
Every library is built static; the build then merges them into the one library CLO links.

### Getting vcpkg
```sh
git init vcpkg && cd vcpkg
git remote add origin https://github.com/microsoft/vcpkg.git
git fetch --depth 1 origin 07f4812200df3d3c931c0c8a6081d3b21fe2bf9f
git checkout FETCH_HEAD
./bootstrap-vcpkg.sh -disableMetrics      # Windows: .\bootstrap-vcpkg.bat -disableMetrics
```
A full `git clone https://github.com/microsoft/vcpkg.git` followed by `git checkout 07f4812200df` works too.

Common options below:
`OVERLAY="--overlay-ports=<this repo>/CLO/vcpkg/ports --overlay-triplets=<this repo>/CLO/vcpkg/triplets"`
(on Windows, `set OVERLAY=...` and use `%OVERLAY%`).

### Windows x64 (`FreeImageLib.lib`, release and debug)
Visual Studio 2022 with the MSVC 14.38 toolset.
```
vcpkg install freeimage:x64-windows-clo %OVERLAY%
```
Then each configuration's libraries go into one `FreeImageLib.lib` with `lib.exe /MACHINE:X64`: FreeImage,
FreeImagePlus, jpeg, libpng16, tiff, lzma, zs, libwebp, libwebpdemux, libwebpmux, libsharpyuv, openjp2,
jxrglue, jpegxr, raw (manual-link), jasper, OpenEXR, OpenEXRCore, Iex, IlmThread, Imath, deflatestatic, openjph.

### WebAssembly (`libFreeImage.a`, wasm32 and wasm64)
Emscripten SDK, with `EMSDK` set and `VCPKG_KEEP_ENV_VARS=EMSDK`. `freeimage[core]` leaves out EXR, J2K/JP2,
JXR and RAW (change 4).
```
vcpkg install freeimage[core]:wasm32-emscripten-clo-fi libjpeg-turbo[jpeg7]:wasm32-emscripten-clo-fi libwebp[simd]:wasm32-emscripten-clo-fi %OVERLAY%
vcpkg install freeimage[core]:wasm64-emscripten-clo-fi libjpeg-turbo[jpeg7]:wasm64-emscripten-clo-fi libwebp[simd]:wasm64-emscripten-clo-fi %OVERLAY%
```
Then, per architecture, the libraries go into one `libFreeImage.a` with `llvm-ar -M`: libFreeImage,
libFreeImagePlus, libjpeg, libpng16, libtiff, liblzma, libz, libwebp, libwebpdemux, libwebpmux, libsharpyuv,
libImath.

### macOS (`libfreeimage.3.18.0.dylib`, universal arm64 + x86_64)
Xcode, plus `brew install pkgconf nasm`.
```sh
for t in arm64 x64; do
  vcpkg install "freeimage:$t-osx-clo-fi" "libwebp[core,libwebpmux,nearlossless,simd]:$t-osx-clo-fi" \
    $OVERLAY --x-install-root="out/$t"
done
for a in arm64:arm64 x64:x86_64; do
  t=${a%%:*}; arch=${a##*:}; L="out/$t/$t-osx-clo-fi/lib"
  clang++ -std=c++17 -dynamiclib -arch $arch -mmacosx-version-min=10.15 \
    -install_name @executable_path/../Frameworks/libfreeimage.3.18.0.dylib \
    -compatibility_version 3.0.0 -current_version 3.18.0 \
    -Wl,-exported_symbols_list,CLO/macos/exports.txt -Wl,-dead_strip \
    -Wl,-force_load,$L/libFreeImage.a -Wl,-force_load,$L/libwebp.a -Wl,-force_load,$L/libwebpmux.a \
    -Wl,-force_load,$L/libwebpdemux.a -Wl,-force_load,$L/libsharpyuv.a \
    $L/manual-link/libraw.a $L/libjasper.a $L/liblcms2.a $L/libjxrglue.a $L/libjpegxr.a $L/libopenjp2.a \
    $L/libOpenEXRUtil-3_4.a $L/libOpenEXR-3_4.a $L/libOpenEXRCore-3_4.a $L/libIlmThread-3_4.a $L/libIex-3_4.a \
    $L/libImath-3_2.a $L/libopenjph.a $L/libdeflate.a $L/libtiff.a $L/liblzma.a $L/libjpeg.a $L/libpng16.a $L/libz.a \
    CLO/so_init.cpp -o out/libfreeimage.$arch.dylib
done
lipo -create out/libfreeimage.arm64.dylib out/libfreeimage.x86_64.dylib -output out/libfreeimage.3.18.0.dylib
```
The macOS triplets do not turn LCMS off, so LibRaw is built with Little-CMS and `liblcms2.a` is linked in.

### Linux x64 (`libfreeimageplus.a`)
Rocky Linux 9, system GCC 11.
```sh
vcpkg install freeimage:x64-linux-clo-fi $OVERLAY --x-install-root=out
```
Then `CLO/so_init.cpp` is compiled (`g++ -O2 -fPIC -c`) and folded into the `Plugin.cpp.o` member of
`libFreeImage.a` with `ld -r` (a member nothing references is not linked, and `Plugin.cpp.o` defines
`FreeImage_Initialise`). The libraries then go into one `libfreeimageplus.a` with `ar -M`: libFreeImage
(with that member), libFreeImagePlus, libjpeg, libpng16, libtiff, liblzma, libwebp, libwebpdemux, libwebpmux,
libsharpyuv, libopenjp2, libjxrglue, libjpegxr, libraw (manual-link), libOpenEXR, libOpenEXRCore, libIex,
libIlmThread, libImath, libdeflate, libopenjph, libz.
