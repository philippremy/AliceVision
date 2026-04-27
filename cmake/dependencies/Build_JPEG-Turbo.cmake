#
# Build_JPEG-Turbo.cmake
#
# Builds an embedded version of JPEG-Turbo

include(AV_ColoredMessage)

function(build_JPEG_Turbo)

  set(AV_DEP_JPEG_Turbo_BUILD_STATIC ON)
  if(BUILD_SHARED_LIBS)
    set(AV_DEP_JPEG_Turbo_BUILD_STATIC OFF)
  endif()

  set(AV_DEP_JPEG_Turbo_VERSION           "3.1.4.1")
  set(AV_DEP_JPEG_Turbo_URL               "https://github.com/libJPEG-Turbo/libJPEG-Turbo/releases/download/${AV_DEP_JPEG_Turbo_VERSION}/libJPEG-Turbo-${AV_DEP_JPEG_Turbo_VERSION}.tar.gz")
  set(AV_DEP_JPEG_Turbo_HASH              "SHA256=ecae8008e2cc9ade2f2c1bb9d5e6d4fb73e7c433866a056bd82980741571a022")
  set(AV_DEP_JPEG_Turbo_EXTRA_CMAKE_FLAGS
    -DENABLE_SHARED=${BUILD_SHARED_LIBS}
    -DENABLE_STATIC=${AV_DEP_JPEG_Turbo_BUILD_STATIC}
    -DREQUIRE_SIMD=OFF  # It will not hard-error if SIMD is not available
    -DWITH_ARITH_DEC=ON
    -DWITH_ARITH_ENC=ON
    -DWITH_JNA=OFF
    -DWITH_JPEG7=ON
    -DWITH_JPEG8=ON
    -DWITH_SIMD=ON
    -DWITH_TURBOJPEG=ON
    -DWITH_TOOLS=OFF
    -DWITH_TESTS=OFF
    -DWITH_FUZZ=OFF
    -DWITH_PROFILE=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_JPEG_Turbo_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of JPEG_Turbo...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(JPEG-Turbo URL ${AV_DEP_JPEG_Turbo_URL} URL_HASH "${AV_DEP_JPEG_Turbo_HASH}")

  # Build the dependency
  av_build_cmake_dependency(JPEG-Turbo
    EXTRA_CMAKE_ARGS ${AV_DEP_JPEG_Turbo_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_JPEG_Turbo()
