#
# Build_Imath.cmake
#
# Builds an embedded version of Imath

include(AV_ColoredMessage)

function(build_Imath)

  set(AV_DEP_Imath_VERSION           "3.2.2")
  set(AV_DEP_Imath_URL               "https://github.com/AcademySoftwareFoundation/Imath/releases/download/v${AV_DEP_Imath_VERSION}/Imath-${AV_DEP_Imath_VERSION}.tar.gz")
  set(AV_DEP_Imath_HASH              "SHA256=0f5a783b424f374e6f27ec8b0c73130e89b08814ac8fa2e84fd7fe0b05862c53")
  set(AV_DEP_Imath_EXTRA_CMAKE_FLAGS
    -DIMATH_INSTALL=ON
    -DIMATH_BUILD_APPLE_FRAMEWORKS=OFF
    -DIMATH_HALF_USE_LOOKUP_TABLE=ON
    -DIMATH_USE_DEFAULT_VISIBILITY=OFF
    -DIMATH_ENABLE_LARGE_STACK=ON
    -DIMATH_USE_NOEXCEPT=ON
    -DIMATH_INSTALL_PKG_CONFIG=ON
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Imath_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Imath...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(Imath URL ${AV_DEP_Imath_URL} URL_HASH "${AV_DEP_Imath_HASH}")

  # Build the dependency
  av_build_cmake_dependency(Imath
    EXTRA_CMAKE_ARGS ${AV_DEP_Imath_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Imath()
