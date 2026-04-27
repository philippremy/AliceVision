#
# Build_flann.cmake
#
# Builds an embedded version of flann

include(AV_ColoredMessage)

function(build_flann)

  set(AV_DEP_flann_VERSION           "1.9.2")
  set(AV_DEP_flann_URL               "https://github.com/flann-lib/flann/archive/refs/tags/${AV_DEP_flann_VERSION}.tar.gz")
  set(AV_DEP_flann_HASH              "SHA256=e26829bb0017f317d9cc45ab83ddcb8b16d75ada1ae07157006c1e7d601c8824")
  set(AV_DEP_flann_EXTRA_CMAKE_FLAGS
    -DBUILD_C_BINDINGS=OFF
    -DBUILD_PYTHON_BINDINGS=OFF
    -DBUILD_MATLAB_BINDINGS=OFF
    -DBUILD_CUDA_LIB=${AV_USE_CUDA}
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_DOC=OFF
    -DUSE_OPENMP=${AV_USE_OPENMP}
    -DUSE_MPI=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_flann_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of flann...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(flann URL ${AV_DEP_flann_URL} URL_HASH "${AV_DEP_flann_HASH}")

  # Build the dependency
  av_build_cmake_dependency(flann
    PKG_CONFIG_PATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/pkgconfig"
    EXTRA_CMAKE_ARGS ${AV_DEP_flann_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_flann()
