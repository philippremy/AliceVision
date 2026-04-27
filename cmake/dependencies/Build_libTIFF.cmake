#
# Build_libTIFF.cmake
#
# Builds an embedded version of libTIFF

include(AV_ColoredMessage)

function(build_libTIFF)

  set(AV_DEP_libTIFF_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_libTIFF_BUILD_STATIC ON)
  endif()

  # Optional image codecs
  set(AV_DEP_libTIFF_IMAGE_CODECS_ARGS)
  if(NOT AV_DEP_JBIG_DISABLED)
    list(APPEND AV_DEP_libTIFF_IMAGE_CODECS_ARGS -Djbig=ON)
  endif()
  if(NOT AV_DEP_libWebP_DISABLED)
    list(APPEND AV_DEP_libTIFF_IMAGE_CODECS_ARGS -Dwebp=ON)
  endif()

  # Fix for Apple/Xcode (HAVE_LD_VERSION_SCRIPT)
  if(APPLE)
    set(AV_DEP_libTIFF_LD_ARGS -DHAVE_LD_VERSION_SCRIPT=OFF)
  endif()

  set(AV_DEP_libTIFF_VERSION           "4.7.1")
  set(AV_DEP_libTIFF_URL               "https://gitlab.com/libtiff/libtiff/-/archive/v${AV_DEP_libTIFF_VERSION}/libtiff-v${AV_DEP_libTIFF_VERSION}.tar.bz2")
  set(AV_DEP_libTIFF_HASH              "SHA256=7bbeb6ece519e302dc68bb820ae17b9cf071baf30f70a4a6b98e9f72e6d8c1eb")
  set(AV_DEP_libTIFF_EXTRA_CMAKE_FLAGS
    -Dtiff-static=${AV_DEP_libTIFF_BUILD_STATIC}
    -Dtiff-tools=OFF
    -Dtiff-tests=OFF
    -Dtiff-contrib=OFF
    -Dtiff-docs=OFF
    -Dtiff-deprecated=OFF
    -Dtiff-install=ON
    -Dzlib=ON       # Only needed for deflate, which we do not use
    -Dlibdeflate=OFF
    -Dpixarlog=OFF
    -Dold-jpeg=OFF
    -Djpeg=ON     # We always build JPEG-Turbo
    -Dlerc=OFF
    -Dlzma=OFF
    -Dzstd=OFF
    ${AV_DEP_libTIFF_IMAGE_CODECS_ARGS} # Remaining image codecs
    ${AV_DEP_libTIFF_LD_ARGS}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_libTIFF_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of libTIFF...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(libTIFF URL ${AV_DEP_libTIFF_URL} URL_HASH "${AV_DEP_libTIFF_HASH}")

  # Build the dependency
  av_build_cmake_dependency(libTIFF
    EXTRA_CMAKE_ARGS ${AV_DEP_libTIFF_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_libTIFF()
