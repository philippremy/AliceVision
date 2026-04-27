# ===============================================
#
# AliceVision - 3D Computer Vision Framework
# MPL-2.0
#
# ===============================================

# Must be set at the top level
cmake_minimum_required(VERSION 3.30)

# ===============================================
# Project version
# ===============================================
set(AV_PROJECT_VERSION_MAJOR    4)
set(AV_PROJECT_VERSION_MINOR    0)
set(AV_PROJECT_VERSION_PATCH    0)
set(AV_PROJECT_VERSION_STATUS   "develop")
set(AV_PROJECT_VERSION "${AV_PROJECT_VERSION_MAJOR}.${AV_PROJECT_VERSION_MINOR}.${AV_PROJECT_VERSION_PATCH}")

# Must be set at the top level
# C++ is always required
project(AliceVision
  DESCRIPTION "3D Computer Vision Framework"
  HOMEPAGE_URL "https://alicevision.org/"
  LANGUAGES C CXX
  VERSION ${AV_PROJECT_VERSION}
)

# This file sets up relevant basic configuration for CMake
include(${CMAKE_SOURCE_DIR}/cmake/modules/AV_CMakeSetup.cmake)

# Compiler Detection
include(AV_CompilerDetection)

# Target-Triple Detection
include(AV_DetermineTargetTriple)

# ===============================================
# Shared build settings
# ===============================================
option(AV_BUILD_DEPENDENCIES              "Build AliceVision with embedded dependencies"      ON)
option(AV_NO_SYSTEM_DEPS                  "Do not use system provided dependencies"           ON)
option(AV_BUILD_UNITTEST                  "Build AliceVision with unit tests"                 ON)
option(AV_BUILD_DOCS                      "Build AliceVision with documentation"              ON)
option(AV_BUILD_ENABLE_RPTAHS             "Build AliceVision with rpaths"                     ON)
option(AV_BUILD_MESHROOM_PLUGIN           "Build AliceVision for use in Meshroom"             ON)
option(AV_BUILD_SWIG_BINDING              "Build the AliceVision Python bindings with SWIG"   ON)
av_conditional_option(AV_BUILD_FRAMEWORKS "Build Apple Frameworks on Apple platforms"
  IF APPLE AND BUILD_SHARED_LIBS
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_ASAN       "Build AliceVision with AddressSanitizer (ASAN) support"
  IF AV_COMPILER_SUPPORTS_ASAN AND CMAKE_BUILD_TYPE STREQUAL Debug
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_UBSAN       "Build AliceVision with UndefinedBehaviorSanitizer (UBSAN) support"
  IF AV_COMPILER_SUPPORTS_UBSAN AND CMAKE_BUILD_TYPE STREQUAL Debug
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_COVERAGE     "Build AliceVision with CodeCoverage (GCC and Clang only)"
  IF AV_COMPILER_GNU_COMPATIBLE AND CMAKE_BUILD_TYPE STREQUAL Debug
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_WITH_LTO     "Build AliceVision with Link-Time-Optimization (LTO/IPO)"
  IF AV_COMPILER_SUPPORTS_LTO AND NOT CMAKE_BUILD_TYPE STREQUAL Debug
  THEN ON
  ELSE OFF
)

# ===============================================
# Shared dependency settings
# ===============================================
option(AV_USE_OPENMP                        "Build AliceVision with OpenMP support"                       ON)
option(AV_USE_CCTAG                         "Build AliceVision with CCTag support"                        ON)
option(AV_USE_APRILTAG                      "Build AliceVision with Apriltag support"                     ON)
option(AV_USE_ALEMBIC                       "Build AliceVision with Alembic support"                      ON)
option(AV_USE_OPENCV                        "Build AliceVision with OpenCV support"                       ON)
option(AV_USE_USD                           "Build AliceVision with USD/PXR support"                      ON)
option(AV_USE_MESHSDFILTER                  "Build AliceVision with MeshSDFilter support"                 ON)
option(AV_USE_CERES_ACCEL_SPARSE            "Require Ceres to be built with sparse acceleration"          ON)
av_conditional_option(AV_USE_ONNX           "Build AliceVision with ONNX support"
  IF DEFINED AV_ONNX_INSTALL_PREFIX
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_USE_CUDA           "Build AliceVision with CUDA support (non-Apple only)"
  IF NOT APPLE
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_USE_POPSIFT        "Build AliceVision with PopSIFT support (CUDA only)"
  IF AV_USE_CUDA
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_USE_UNCERTAINTYTE  "Build AliceVision with uncertaintyTE support (CUDA only)"
  IF AV_USE_CUDA
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_USE_ONNX_CUDA      "Build AliceVision with ONNX CUDA acceleration (CUDA only)"
  IF AV_USE_CUDA AND AV_USE_ONNX
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_USE_OPENCV_CONTRIB "Build AliceVision with OpenCV contribution modules"
  IF AV_USE_OPENCV
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_USE_OPENCV_SIFT    "Build AliceVision with OpenCV SIFT support"
  IF AV_USE_OPENCV AND AV_USE_OPENCV_CONTRIB
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_USE_MOSEK          "Build AliceVision with MOSEK and CoinOsiMsk support"
  IF DEFINED AV_MOSEK_DIR
  THEN ON
  ELSE OFF
)
set(AV_USE_IMAGE_CODECS
  PNG
  RAW
  WebP
  CACHE STRING
  "Additional image codecs to support in the project (PNG, RAW, OpenJPEG, WebP, JPEG-XL, GIF, JBIG).\
  JPEG, JPEG2000, EXR and TIFF are always supported"
)

# ===============================================
# Shared project component settings
# ===============================================
option(AV_BUILD_SFM                                "Build AliceVision Structure-from-Motion (SfM) libraries"    ON)
option(AV_BUILD_SOFTWARE                           "Build AliceVision tools/executables"                        ON)
av_conditional_option(AV_BUILD_MVS                 "Build AliceVision Multi View Stereo (MVS) libraries"
  IF AV_BUILD_SFM
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_HDR                 "Build AliceVision High Dynamic Range libraries"
  IF AV_BUILD_SFM
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_SEGMENTATION        "Build AliceVision Segmentation libraries"
  IF AV_BUILD_SFM
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_PHOTOMETRICSTEREO   "Build AliceVision Segmentation libraries"
  IF AV_BUILD_SFM
  THEN ON
  ELSE OFF
)
av_conditional_option(AV_BUILD_LIDAR               "Build The AliceVision LiDAR libraries"
  IF AV_BUILD_SFM
  THEN ON
  ELSE OFF
)

# Project configuration logger
include(AV_ProjectConfigurationLogger)

# Dependency management
include(AV_DependencyManagement)

# Dependency logger
include(AV_DependencyLogger)

# Dependency builder
include(AV_DependencyBuilder)

# Dependency finder
include(AV_DependencyFinder)

# Dependency finder logger
include(AV_DependencyFinderLogger)

# Prerequisites are fulfilled, switch to sources
add_subdirectory(src)
