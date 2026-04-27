#
# Build_libPNG.cmake
#
# Builds an embedded version of libPNG

include(AV_ColoredMessage)

function(build_libPNG)

  set(AV_DEP_libPNG_BUILD_STATIC ON)
  if(BUILD_SHARED_LIBS)
    set(AV_DEP_libPNG_BUILD_STATIC OFF)
  endif()

  set(AV_DEP_libPNG_VERSION           "1.6.57")
  set(AV_DEP_libPNG_URL               "https://github.com/pnggroup/libpng/archive/refs/tags/v${AV_DEP_libPNG_VERSION}.tar.gz")
  set(AV_DEP_libPNG_HASH              "SHA256=4cbb7b0746edc1683c9581b373365e955133b7f1243f171b7d1535b4415dfedb")
  set(AV_DEP_libPNG_EXTRA_CMAKE_FLAGS
    -DPNG_SHARED=${BUILD_SHARED_LIBS}
    -DPNG_STATIC=${AV_DEP_libPNG_BUILD_STATIC}
    -DPNG_FRAMEWORK=OFF
    -DPNG_TESTS=OFF
    -DPNG_TOOLS=OFF
    -DPNG_HARDWARE_OPTIMIZATIONS=OFF
    -DPNG_BUILD_ZLIB=OFF    # We always build a zlib
    -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=OFF  # ! Overwrite standard arg ! This messes up the zlib versioning on macOS!
  )

  # Return early if the dependency should not be built
  if(AV_DEP_libPNG_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of libPNG...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(libPNG URL ${AV_DEP_libPNG_URL} URL_HASH "${AV_DEP_libPNG_HASH}")

  if(AV_IS_CROSSCOMPILING)
    set(AV_DEP_libPNG_NO_OPT_FLAG NO_OPT)
  endif()

  # Build the dependency
  av_build_cmake_dependency(libPNG
    ${AV_DEP_libPNG_NO_OPT_FLAG}  # For some reason passing many flags will break libPNG if cross-compiled
    EXTRA_CMAKE_ARGS ${AV_DEP_libPNG_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_libPNG()
