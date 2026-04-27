#
# Build_JPEG-XL.cmake
#
# Builds an embedded version of JPEG-XL

include(AV_ColoredMessage)

function(build_JPEG_XL)

  set(AV_DEP_JPEG_XL_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_JPEG_XL_BUILD_STATIC ON)
  endif()

  # FIXME: Remove when Xcode/JPEG-XL stops doing funny things with its object
  #        library targets
  if(${CMAKE_GENERATOR} STREQUAL "Xcode")
    set(AV_DEP_JPEG_XL_XCODE_FIX -G "Unix Makefiles")
  endif()

  set(AV_DEP_JPEG_XL_GIT_REPO          "https://github.com/libjxl/libjxl.git")
  set(AV_DEP_JPEG_XL_GIT_TAG           "v0.11.2")
  set(AV_DEP_JPEG_XL_EXTRA_CMAKE_FLAGS
    -DJPEGXL_ENABLE_FUZZERS=OFF
    -DPROVISION_DEPENDENCIES=OFF
    -DJPEGXL_ENABLE_DEVTOOLS=OFF
    -DJPEGXL_ENABLE_TOOLS=OFF
    -DJPEGXL_ENABLE_DOXYGEN=OFF
    -DJPEGXL_ENABLE_MANPAGES=OFF
    -DJPEGXL_ENABLE_BENCHMARK=OFF
    -DJPEGXL_ENABLE_EXAMPLES=OFF
    -DJPEGXL_BUNDLE_LIBPNG=OFF
    -DJPEGXL_ENABLE_JNI=OFF
    -DJPEGXL_ENABLE_SJPEG=OFF
    -DJPEGXL_ENABLE_OPENEXR=ON    # We always build OpenEXR
    -DJPEGXL_ENABLE_VIEWERS=OFF
    -DJPEGXL_ENABLE_PLUGINS=OFF
    -DJPEGXL_ENABLE_COVERAGE=OFF
    -DJPEGXL_ENABLE_TRANSCODE_JPEG=ON
    -DJPEGXL_ENABLE_BOXES=ON
    -DJPEGXL_STATIC=OFF
    -DJPEGXL_WARNINGS_AS_ERRORS=OFF
    -DJPEGXL_TEST_TOOLS=OFF
    -DJPEGXL_ENABLE_WASM_THREADS=OFF
    -DJPEGXL_ENABLE_LTO=${AV_BUILD_WITH_LTO}
    -DJPEGXL_FORCE_SYSTEM_BROTLI=ON   # JPEG-XL does funny stuff with rpaths if building brotli :(
    -DJPEGXL_FORCE_SYSTEM_GTEST=OFF
    -DJPEGXL_FORCE_SYSTEM_LCMS2=OFF
    -DJPEGXL_FORCE_SYSTEM_HWY=OFF
    ${AV_DEP_JPEG_XL_XCODE_FIX}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_JPEG_XL_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of JPEG-XL...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(JPEG-XL GIT_REPO ${AV_DEP_JPEG_XL_GIT_REPO} GIT_TAG "${AV_DEP_JPEG_XL_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(JPEG-XL
    EXTRA_CMAKE_ARGS ${AV_DEP_JPEG_XL_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_JPEG_XL()
