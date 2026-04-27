#
# AV_DependencyManagement.cmake
#
# This file declares the dependencies required to be available to build the
# project

# Include common utilities
include(AV_DependencyUtils)

# ===============================================
# Core Components
# ===============================================
av_define_dependency(OpenMP
  DISABLE_IF NOT AV_USE_OPENMP
)

av_define_dependency(zlib)
av_define_dependency(Boost)

# ===============================================
# Math Components
# ===============================================
av_define_dependency(MOSEK
  DISABLE_IF NOT AV_USE_MOSEK
  NEVER_BUILD
)

av_define_dependency(CoinUtils
  REQUIRES BLAS-LAPACK
)

av_define_dependency(CoinOsi
  REQUIRES CoinUtils
  OPTIONAL_REQUIRES "MOSEK IF AV_USE_MOSEK"
)

av_define_dependency(CoinClp
  REQUIRES CoinUtils CoinOsi
)

av_define_dependency(Eigen3
  OPTIONAL_REQUIRES "OpenMP IF AV_USE_OPENMP"
)

av_define_dependency(Ceres
  REQUIRES Eigen3 BLAS-LAPACK
  OPTIONAL_REQUIRES "SuiteSparse IF AV_USE_CERES_ACCEL_SPARSE"
)

av_define_dependency(LEMON)

# ===============================================
# Image Dependencies
# ===============================================
av_define_dependency(OpenEXR
  REQUIRES OpenJPH Imath oneTBB
)

av_define_dependency(OpenImageIO
  REQUIRES Imath OpenEXR libTIFF OpenColorIO JPEG-Turbo zlib oneTBB OpenJPH
  OPTIONAL_REQUIRES
    "libPNG IF AV_USE_IMAGE_CODECS MATCHES PNG"
    "libRAW IF AV_USE_IMAGE_CODECS MATCHES RAW"
    "OpenJPEG IF AV_USE_IMAGE_CODECS MATCHES OpenJPEG"
    "libWebP IF AV_USE_IMAGE_CODECS MATCHES WebP"
    "JPEG-XL IF AV_USE_IMAGE_CODECS MATCHES JPEG-XL"
    "GIFLIB IF AV_USE_IMAGE_CODECS MATCHES GIF"
    "OpenCV IF AV_USE_OPENCV"
)

av_define_dependency(OpenCV
  REQUIRES zlib Eigen3 JPEG-Turbo OpenEXR libTIFF BLAS-LAPACK CoinClp
  DISABLE_IF NOT AV_USE_OPENCV
  OPTIONAL_REQUIRES
    "JPEG-XL IF AV_USE_IMAGE_CODECS MATCHES JPEG-XL"
    "OpenJPEG IF AV_USE_IMAGE_CODECS MATCHES OpenJPEG"
    "libWebP IF AV_USE_IMAGE_CODECS MATCHES WebP"
    "libPNG IF AV_USE_IMAGE_CODECS MATCHES PNG"
    "OpenMP IF AV_USE_OPENMP"
)

# ===============================================
# Utility Dependencies
# ===============================================
av_define_dependency(Expat)

# ===============================================
# Feature Extraction Dependencies
# ===============================================
av_define_dependency(VLFeat
  OPTIONAL_REQUIRES "OpenMP IF AV_USE_OPENMP"
)

av_define_dependency(CCTag
  REQUIRES Boost OpenCV Eigen3 oneTBB
  DISABLE_IF NOT AV_USE_CCTAG
)

av_define_dependency(AprilTag
  DISABLE_IF NOT AV_USE_APRILTAG
)

av_define_dependency(PopSIFT
  REQUIRES Boost
  DISABLE_IF NOT AV_USE_POPSIFT
)

# ===============================================
# Algorithm Components
# ===============================================
av_define_dependency(UncertaintyTE
  REQUIRES Gflags Eigen3 Ceres BLAS-LAPACK Magma
  DISABLE_IF NOT AV_USE_UNCERTAINTYTE
)

av_define_dependency(nanoflann)
av_define_dependency(flann
  REQUIRES lz4
)

# ===============================================
# Geometry Components
# ===============================================
av_define_dependency(Geogram
  REQUIRES oneTBB
)

av_define_dependency(MeshSDFilter
  DISABLED_IF NOT AV_USE_MESHSDFILTER
  REQUIRES OpenMesh Eigen3
  OPTIONAL_REQUIRES "OpenMP IF AV_USE_OPENMP"
)

# ===============================================
# Asset Components
# ===============================================
av_define_dependency(USD
  REQUIRES OpenImageIO OpenColorIO oneTBB OpenSubdiv
  DISABLE_IF NOT AV_USE_USD
  OPTIONAL_REQUIRES "Alembic IF AV_USE_ALEMBIC"
)

av_define_dependency(Alembic
  REQUIRES Imath zlib
  DISABLE_IF NOT AV_USE_ALEMBIC
)

av_define_dependency(Assimp
  REQUIRES zlib
)

av_define_dependency(E57Format
  REQUIRES XercesC
  DISABLE_IF NOT AV_BUILD_LIDAR
)

# ===============================================
# Transitive Dependencies
# ===============================================
av_define_dependency(lz4
  TRANSITIVE
)

av_define_dependency(brotli
  TRANSITIVE
)

av_define_dependency(SuiteSparse
  TRANSITIVE
  REQUIRES oneTBB BLAS-LAPACK
  OPTIONAL_REQUIRES "OpenMP IF AV_USE_OPENMP"
)

av_define_dependency(BLAS-LAPACK
  TRANSITIVE
  OPTIONAL_REQUIRES "OpenMP IF AV_USE_OPENMP"
  BUILD_ONLY_IF NOT APPLE
)

av_define_dependency(Imath
  TRANSITIVE
)

av_define_dependency(OpenJPH
  TRANSITIVE
)

av_define_dependency(libTIFF
  TRANSITIVE
  REQUIRES zlib JPEG-Turbo
  OPTIONAL_REQUIRES
    "JBIG IF AV_USE_IMAGE_CODECS MATCHES JBIG"
    "libWebP IF AV_USE_IMAGE_CODECS MATCHES WebP"
)

av_define_dependency(OpenColorIO
  TRANSITIVE
  REQUIRES Expat Imath zlib OpenEXR
)

av_define_dependency(JPEG-Turbo
  TRANSITIVE
)

av_define_dependency(libPNG
  TRANSITIVE
  REQUIRES zlib
)

av_define_dependency(libRAW
  TRANSITIVE
  OPTIONAL_REQUIRES "OpenMP IF AV_USE_OPENMP"
)

av_define_dependency(OpenJPEG
  TRANSITIVE
)

av_define_dependency(oneTBB
  TRANSITIVE
)

av_define_dependency(GIFLIB
  TRANSITIVE
)

av_define_dependency(libWebP
  TRANSITIVE
)

av_define_dependency(JPEG-XL
  TRANSITIVE
  REQUIRES JPEG-Turbo OpenEXR brotli
  OPTIONAL_REQUIRES
    "GIFLIB IF AV_USE_IMAGE_CODECS MATCHES GIF"
    "libPNG IF AV_USE_IMAGE_CODECS MATCHES PNG"
)

av_define_dependency(JBIG
  TRANSITIVE
)

av_define_dependency(Gflags
  TRANSITIVE
)

av_define_dependency(Magma
  TRANSITIVE
  REQUIRES BLAS-LAPACK
  OPTIONAL_REQUIRES "OpenMP IF AV_USE_OPENMP"
)

av_define_dependency(XercesC
  TRANSITIVE
)

av_define_dependency(OpenSubdiv
  TRANSITIVE
  REQUIRES oneTBB OpenMP
)

av_define_dependency(OpenMesh)

# Finalize dependencies
av_finalize_dependencies()
