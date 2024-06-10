## Build requirements on macOS

- LLVM (and Clang) 18 (*not* AppleClang, use [Homebrew LLVM](https://formulae.brew.sh/formula/llvm#default) instead!)
- Git
- NASM
- CMake
- Homebrew (required to be in `$PATH`, because we need to find the executable of Bison 3.X in order for SWIG to compiler correctly)
- PugiXML
- Boost
- Java JDK 21
- Xcode Command Line Tools (for the macOS SDK)
- libXercesC
- glog

## Hints

Building this library will take a considerable amount of time (i.e., more than 1,5h for sure): We need to build *all* of our dependencies from scratch, even big libraries and binaries like ffmpeg, OpenCV, Assimp, GraphBLAS, etc.

Just wait, ignore *all* warnings (especially Geogram emits literally millions of them) and hope that `make` will not end with an error. Then - and only then - something went wrong. Otherwise, it just might need more time, even when it appears to do nothing.