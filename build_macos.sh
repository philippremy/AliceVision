#!/bin/bash

#
#
#
#   Created by Philipp Remy, 06/07/2024
#
#
#

# --------------------------------------------
#
#   We need to enable specific flags for CMake
#
# --------------------------------------------

USE_CUDA=OFF              # Obviously not.
USE_OPENMP=ON             # Will be *very* slow otherwise. This *is* possible on macOS (We only have to trick a little [and have a full LLVM installed.])
BUILD_DEPENDENCIES=ON     # We better do this. Otherwise the user must fetch everything on their own, lots of possible failure points.
USE_POPSIFT=OFF           # This is CUDA based, so this is a no.
USE_GPU_SIFT_IMPL=OFF     # See above.
USE_OPEN_GV=ON            # We build them, why not use them?
USE_ONNX_RT=ON            # This is available on macOS, so use it.
USE_OPEN_CV=ON            # Again, this will be build and therefore it can be included.
USE_OPEN_CV_EXTRA=ON      # Idk. We will see.
ADD_RPATH=ON              # I think this is a good idea. Otherwise we will have problems with dyld later.
USE_PNG=OFF               # Currently fails for some unclear reason.
BUILD_ZLIB=ON             # Somehow Geogram got a hickup when using their bundled stuff...
BUILD_LEMON=OFF           # This currently does not work because it uses "register", which is deprecated in C++17
BUILD_LIBVPX=OFF          # This falsely adds Linux linking flags

# --------------------------------------------
#
#   Make our build folder and cd into it.
#
# --------------------------------------------

# If we are not in the expected folder, unexpected things will happen (probably).
if [ "$(basename $(pwd))" != "AliceVision" ]; then
    echo "Basename is not AliceVision! Are you sure you cloned the project and left *everything* untouched?"
    exit
fi

mkdir build
cd build

# --------------------------------------------
#
#   Export important paths!
#
# --------------------------------------------

export CC=/usr/local/opt/llvm/bin/clang
export CXX=/usr/local/opt/llvm/bin/clang++
export LDFLAGS="-L/usr/local/lib -std=c++17"
export CPPFLAGS="-I/usr/local/opt/llvm/include -lc++abi -std=c++17"

# --------------------------------------------
#
#   Generate the CMake command
#
# --------------------------------------------

CC=/usr/local/opt/llvm/bin/clang \
CXX=/usr/local/opt/llvm/bin/clang++ \
LDFLAGS="-L/usr/local/lib -std=c++17" \
CPPFLAGS="-I/usr/local/opt/llvm/include -lc++abi -std=c++17" \
cmake -DAV_USE_CUDA=${USE_CUDA} \
-DAV_USE_OPENMP=${USE_OPENMP} \
-DAV_BUILD_POPSIFT=${USE_POPSIFT} \
-DALICEVISION_USE_POPSIFT=${USE_POPSIFT} \
-DALICEVISION_USE_OPENGV=${USE_OPEN_GV} \
-DALICEVISION_USE_ONNX=${USE_ONNX_RT} \
-DALICEVISION_USE_CUDA=${USE_CUDA} \
-DALICEVISION_USE_OPENCV=${USE_OPEN_CV} \
-DALICEVISION_USE_OPENCV_CONTRIB=${USE_OPEN_CV_EXTRA} \
-DALICEVISION_USE_RPATH=${ADD_RPATH} \
-DALICEVISION_BUILD_DEPENDENCIES=${BUILD_DEPENDENCIES} \
-DAV_BUILD_DEPENDENCIES_PARALLEL=$(sysctl -n hw.logicalcpu_max) \
-DAV_BUILD_PNG=${USE_PNG} \
-DAV_BUILD_ZLIB=${BUILD_ZLIB} \
-DAV_BUILD_LEMON=${BUILD_LEMON} \
-DAV_BUILD_VPX=${BUILD_LIBVPX} \
.. \
-G "Unix Makefiles"

# --------------------------------------------
#
#   Execute Ninja
#
# --------------------------------------------

CC=/usr/local/opt/llvm/bin/clang \
CXX=/usr/local/opt/llvm/bin/clang++ \
LDFLAGS=-L/usr/local/lib \
CPPFLAGS="-I/usr/local/opt/llvm/include -lc++abi" \
sudo make \
-j$(sysctl -n hw.logicalcpu_max) \