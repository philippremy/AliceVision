#
# Build_BLAS_LAPACK.cmake
#
# Builds an embedded version of BLAS+LAPACK

include(AV_ColoredMessage)

function(build_BLAS_LAPACK)

  set(AV_DEP_BLAS_LAPACK_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_BLAS_LAPACK_BUILD_STATIC ON)
  endif()

  set(AV_DEP_BLAS_LAPACK_VERSION           "0.3.33")
  set(AV_DEP_BLAS_LAPACK_URL               "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${AV_DEP_BLAS_LAPACK_VERSION}/OpenBLAS-${AV_DEP_BLAS_LAPACK_VERSION}.tar.gz")
  set(AV_DEP_BLAS_LAPACK_HASH              "SHA256=6761af1d9f5d353ab4f0b7497be2643313b36c8f31caec0144bfef198e71e6ab")
  set(AV_DEP_BLAS_LAPACK_EXTRA_CMAKE_FLAGS
    -DBUILD_WITHOUT_LAPACK=OFF
    -DBUILD_WITHOUT_LAPACKE=OFF
    -DBUILD_LAPACK_DEPRECATED=ON
    -DBUILD_TESTING=OFF
    -DBUILD_BENCHMARKS=OFF
    -DC_LAPACK=ON
    -DBUILD_WITHOUT_CBLAS=OFF
    -DDYNAMIC_ARCH=OFF
    -DDYNAMIC_OLDER=OFF
    -DBUILD_RELAPACK=OFF
    -DUSE_LOCKING=ON
    -DUSE_PERL=OFF
    -DNO_WARMUP=ON
    -DFIXED_LIBNAME=OFF
    -DCPP_THREAD_SAFETY_TEST=OFF
    -DCPP_THREAD_SAFETY_GEMV=OFF
    -DBUILD_STATIC_LIBS=${AV_DEP_BLAS_LAPACK_BUILD_STATIC}
    -DUSE_OPENMP=${AV_USE_OPENMP}
    -DUSE_THREAD=ON
    -DNOFORTRAN=ON
  )

  # Return early if the dependency should not be built
  if(AV_DEP_BLAS-LAPACK_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of BLAS-LAPACK...")
    return()
  endif()

  # This cannot be built reliably on macOS (and it never should), Apple users
  # should utilize Accelerate.framework
  if(APPLE)
    message(FATAL_ERROR "Building BLAS/LAPACK on Apple platforms is not supported!")
  endif()

  # Make the target available
  av_make_dependency_available(BLAS_LAPACK URL ${AV_DEP_BLAS_LAPACK_URL} URL_HASH "${AV_DEP_BLAS_LAPACK_HASH}")

  # Build the dependency
  av_build_cmake_dependency(BLAS_LAPACK
    EXTRA_CMAKE_ARGS ${AV_DEP_BLAS_LAPACK_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_BLAS_LAPACK()
