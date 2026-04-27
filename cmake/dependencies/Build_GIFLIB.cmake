#
# Build_GIFLIB.cmake
#
# Builds an embedded version of GIFLIB

include(AV_ColoredMessage)

function(build_GIFLIB)

  set(AV_DEP_GIFLIB_VERSION           "6.1.3")
  set(AV_DEP_GIFLIB_VERSION_MAJOR     "6")
  set(AV_DEP_GIFLIB_URL               "https://sourceforge.net/projects/giflib/files/giflib-${AV_DEP_GIFLIB_VERSION_MAJOR}.x/giflib-${AV_DEP_GIFLIB_VERSION}.tar.gz")
  set(AV_DEP_GIFLIB_HASH              "SHA256=b65b66b99f0424b93525f987386f22fc5efb9da2bfc92ad4a532249aaffbab0e")
  set(AV_DEP_GIFLIB_EXTRA_CMAKE_FLAGS)

  # Return early if the dependency should not be built
  if(AV_DEP_GIFLIB_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of GIFLIB...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(GIFLIB URL ${AV_DEP_GIFLIB_URL} URL_HASH "${AV_DEP_GIFLIB_HASH}")

  # We must overlay with a custom CMakeLists.txt, because JBIG does not have a
  # native CMake build system
  av_overlay_with_cmakelists(GIFLIB)

  # Build the dependency
  av_build_cmake_dependency(GIFLIB)

endfunction()

# Invoke the function automatically
build_GIFLIB()
