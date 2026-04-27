#
# Build_libWebP.cmake
#
# Builds an embedded version of libWebP

include(AV_ColoredMessage)

function(build_libWebP)

  set(AV_DEP_libWebP_LINK_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_libWebP_LINK_STATIC ON)
  endif()

  set(AV_DEP_libWebP_VERSION           "1.6.0")
  set(AV_DEP_libWebP_URL               "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${AV_DEP_libWebP_VERSION}.tar.gz")
  set(AV_DEP_libWebP_HASH              "SHA256=e4ab7009bf0629fd11982d4c2aa83964cf244cffba7347ecd39019a9e38c4564")
  set(AV_DEP_libWebP_EXTRA_CMAKE_FLAGS
    -DWEBP_LINK_STATIC=${AV_DEP_libWebP_LINK_STATIC}
    -DWEBP_ENABLE_SIMD=ON
    -DWEBP_BUILD_ANIM_UTILS=OFF
    -DWEBP_BUILD_CWEBP=OFF
    -DWEBP_BUILD_DWEBP=OFF
    -DWEBP_BUILD_GIF2WEBP=OFF
    -DWEBP_BUILD_IMG2WEBP=OFF
    -DWEBP_BUILD_VWEBP=OFF
    -DWEBP_BUILD_WEBPINFO=OFF
    -DWEBP_BUILD_LIBWEBPMUX=ON
    -DWEBP_BUILD_WEBPMUX=OFF
    -DWEBP_BUILD_WEBP_JS=OFF
    -DWEBP_BUILD_FUZZTEST=OFF
    -DWEBP_USE_THREAD=ON
    -DWEBP_NEAR_LOSSLESS=ON
    -DWEBP_ENABLE_SWAP_16BIT_CSP=OFF
    -DWEBP_BITTRACE=OFF
    -DWEBP_ENABLE_WUNUSED_RESULT=ON
    -DWEBP_BUILD_EXTRAS=OFF
    -DWEBP_FIND_IMG_LIBS=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_libWebP_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of libWebP...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(libWebP URL ${AV_DEP_libWebP_URL} URL_HASH "${AV_DEP_libWebP_HASH}")

  # Build the dependency
  av_build_cmake_dependency(libWebP
    EXTRA_CMAKE_ARGS ${AV_DEP_libWebP_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_libWebP()
