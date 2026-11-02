// FreeImage.cpp's shared-object init (left out of the FREEIMAGE_LIB static build this dylib is
// linked from): the app calls FreeImage_Initialise itself only where it links FreeImage statically
// (#ifdef FREEIMAGE_LIB), so the dylib must register its plugins on load.
#include <cstdint>
typedef int32_t BOOL;
extern "C" void FreeImage_Initialise(BOOL load_local_plugins_only);
extern "C" void FreeImage_DeInitialise();

__attribute__((constructor)) static void FreeImage_SO_Initialise() { FreeImage_Initialise(0); }
__attribute__((destructor)) static void FreeImage_SO_DeInitialise() { FreeImage_DeInitialise(); }
