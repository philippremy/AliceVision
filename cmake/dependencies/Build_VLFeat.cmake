#
# Build_VLFeat.cmake
#
# Builds an embedded version of VLFeat

include(AV_ColoredMessage)

function(build_VLFeat)

  set(AV_DEP_VLFeat_USE_SSE2 OFF)
  if(USE_SSE2)
    set(AV_DEP_VLFeat_USE_SSE2 ON)
  endif()

  set(AV_DEP_VLFeat_USE_AVX OFF)
  if(USE_AVX)
    set(AV_DEP_VLFeat_USE_AVX ON)
  endif()

  set(AV_DEP_VLFeat_VERSION           "0.9.21")
  set(AV_DEP_VLFeat_URL               "https://github.com/vlfeat/vlfeat/archive/refs/tags/v${AV_DEP_VLFeat_VERSION}.tar.gz")
  set(AV_DEP_VLFeat_HASH              "SHA256=221d7fb5103f004cc90201307fd1acb080c0caf5c2c26435ba1d5307c07e8cce")
  set(AV_DEP_VLFeat_EXTRA_CMAKE_FLAGS
    -DVL_USE_SSE=${AV_DEP_VLFeat_USE_SSE2}
    -DVL_USE_AVX=${AV_DEP_VLFeat_USE_AVX}
    -DVL_USE_THREADS=ON   # We always want to use Threads
    -DVL_USE_OPENMP=${AV_USE_OPENMP}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_VLFeat_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of VLFeat...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(VLFeat URL ${AV_DEP_VLFeat_URL} URL_HASH "${AV_DEP_VLFeat_HASH}")

  # We must overlay with a custom CMakeLists.txt, because VLFeat does not have
  # a native CMake build system
  av_overlay_with_cmakelists(VLFeat)

  # Build the dependency
  av_build_cmake_dependency(VLFeat
    EXTRA_CMAKE_ARGS ${AV_DEP_VLFeat_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_VLFeat()
