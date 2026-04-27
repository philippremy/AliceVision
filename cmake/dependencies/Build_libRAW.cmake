#
# Build_libRAW.cmake
#
# Builds an embedded version of libRAW

include(AV_ColoredMessage)

function(build_libRAW)

  set(AV_DEP_libRAW_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_libRAW_BUILD_STATIC ON)
  endif()

  set(AV_DEP_libRAW_CMAKE_GIT_REPO    "https://github.com/LibRaw/LibRaw-cmake")
  set(AV_DEP_libRAW_CMAKE_GIT_TAG     "master")
  set(AV_DEP_libRAW_VERSION           "0.22.1")
  set(AV_DEP_libRAW_URL               "https://github.com/LibRaw/LibRaw/archive/refs/tags/${AV_DEP_libRAW_VERSION}.tar.gz")
  set(AV_DEP_libRAW_HASH              "SHA256=e676248284075605aa2697a66eeed7dc258820bd1d4988c724d29edffd726726")
  set(AV_DEP_libRAW_EXTRA_CMAKE_FLAGS
    -DLIBRAW_PATH=${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/libRAWSources  # Path to the sources
    -DENABLE_OPENMP=${AV_USE_OPENMP}
    -DENABLE_LCMS=OFF
    -DENABLE_JASPER=OFF
    -DENABLE_EXAMPLES=OFF
    -DENABLE_RAWSPEED=OFF
    -DENABLE_DCRAW_DEBUG=OFF
    -DENABLE_X3FTOOLS=OFF
    -DENABLE_6BY9RPI=OFF
    -DLIBRAW_UNINSTALL_TARGET=ON
    -DLIBRAW_INSTALL=ON
  )

  # Return early if the dependency should not be built
  if(AV_DEP_libRAW_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of libRAW...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(libRAW GIT_REPO ${AV_DEP_libRAW_CMAKE_GIT_REPO} GIT_TAG "${AV_DEP_libRAW_CMAKE_GIT_TAG}")

  # IMPORTANT! We need to use the CMake module as the "dependency" name and
  # download the actual source using a different target
  av_make_dependency_available(libRAWSources URL ${AV_DEP_libRAW_URL} URL_HASH ${AV_DEP_libRAW_HASH} NO_COUNT)

  # Build the dependency
  av_build_cmake_dependency(libRAW
    EXTRA_CMAKE_ARGS ${AV_DEP_libRAW_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_libRAW()
