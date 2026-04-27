#
# Build_JBIG.cmake
#
# Builds an embedded version of JBIG

include(AV_ColoredMessage)

function(build_JBIG)

  set(AV_DEP_JBIG_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_JBIG_BUILD_STATIC ON)
  endif()

  set(AV_DEP_JBIG_VERSION           "2.1")
  set(AV_DEP_JBIG_URL               "https://www.cl.cam.ac.uk/~mgk25/jbigkit/download/jbigkit-${AV_DEP_JBIG_VERSION}.tar.gz")
  set(AV_DEP_JBIG_HASH              "SHA256=de7106b6bfaf495d6865c7dd7ac6ca1381bd12e0d81405ea81e7f2167263d932")
  set(AV_DEP_JBIG_EXTRA_CMAKE_FLAGS)

  # Return early if the dependency should not be built
  if(AV_DEP_JBIG_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of JBIG...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(JBIG URL ${AV_DEP_JBIG_URL} URL_HASH "${AV_DEP_JBIG_HASH}")

  # We must overlay with a custom CMakeLists.txt, because JBIG does not have a
  # native CMake build system
  av_overlay_with_cmakelists(JBIG)

  # Build the dependency
  av_build_cmake_dependency(JBIG)

endfunction()

# Invoke the function automatically
build_JBIG()
