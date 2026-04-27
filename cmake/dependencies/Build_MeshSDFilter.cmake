#
# Build_MeshSDFilter.cmake
#
# Builds an embedded version of MeshSDFilter

include(AV_ColoredMessage)

function(build_MeshSDFilter)

  set(AV_DEP_MeshSDFilter_GIT_REPO               "https://github.com/bldeng/MeshSDFilter")
  set(AV_DEP_MeshSDFilter_GIT_TAG                "master")
  set(AV_DEP_MeshSDFilter_EXTRA_CMAKE_FLAGS
    -DMESHSDFILTER_USE_OPENMP=${AV_USE_OPENMP}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_MeshSDFilter_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of MeshSDFilter...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(MeshSDFilter GIT_REPO ${AV_DEP_MeshSDFilter_GIT_REPO} GIT_TAG "${AV_DEP_MeshSDFilter_GIT_TAG}" NO_GIT_CHECK)

  # We must overlay with a custom CMakeLists.txt, because MeshSDFilter's CMake
  # build system is too outdated to accomodate our needs
  av_overlay_with_cmakelists(MeshSDFilter
    FORCE_OVERWRITE # We overwrite an exisiting CMake build system
  )

  # Build the dependency
  av_build_cmake_dependency(MeshSDFilter
    EXTRA_CMAKE_ARGS ${AV_DEP_MeshSDFilter_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_MeshSDFilter()
