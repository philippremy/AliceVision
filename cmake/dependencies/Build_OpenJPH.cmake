#
# Build_OpenJPH.cmake
#
# Builds an embedded version of OpenJPH

include(AV_ColoredMessage)

function(build_OpenJPH)

  set(AV_DEP_OpenJPH_VERSION           "0.27.0")
  set(AV_DEP_OpenJPH_URL               "https://github.com/aous72/OpenJPH/archive/refs/tags/${AV_DEP_OpenJPH_VERSION}.tar.gz")
  set(AV_DEP_OpenJPH_HASH              "SHA256=f6768e927d8e4e4884a2efcf500a88d1b6714a48d69516332a9256803a3c8343")
  set(AV_DEP_OpenJPH_EXTRA_CMAKE_FLAGS
    -DOJPH_ENABLE_TIFF_SUPPORT=OFF # Only used in the Apps
    -DOJPH_BUILD_TESTS=OFF
    -DOJPH_BUILD_EXECUTABLES=OFF
    -DOJPH_BUILD_STREAM_EXPAND=OFF
    -DOJPH_BUILD_FUZZER=OFF
    -DOJPH_DISABLE_SIMD=OFF
    -DOJPH_DISABLE_SSE=OFF
    -DOJPH_DISABLE_SSE2=OFF
    -DOJPH_DISABLE_SSSE3=OFF
    -DOJPH_DISABLE_SSE4=OFF
    -DOJPH_DISABLE_AVX=OFF
    -DOJPH_DISABLE_AVX2=OFF
    -DOJPH_DISABLE_AVX512=OFF
    -DOJPH_DISABLE_NEON=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenJPH_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenJPH...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(OpenJPH URL ${AV_DEP_OpenJPH_URL} URL_HASH "${AV_DEP_OpenJPH_HASH}")

  # Build the dependency
  av_build_cmake_dependency(OpenJPH
    EXTRA_CMAKE_ARGS ${AV_DEP_OpenJPH_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenJPH()
