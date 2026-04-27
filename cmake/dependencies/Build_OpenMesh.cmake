#
# Build_OpenMesh.cmake
#
# Builds an embedded version of OpenMesh

include(AV_ColoredMessage)

function(build_OpenMesh)

  # FIXME: Remove when Xcode stops doing funny stuff
  if(${CMAKE_GENERATOR} STREQUAL "Xcode")
    set(AV_DEP_OpenMesh_XL_XCODE_FIX -G "Unix Makefiles")
  endif()

  set(AV_DEP_OpenMesh_GIT_REPO               "https://gitlab.vci.rwth-aachen.de:9000/OpenMesh/OpenMesh.git")
  set(AV_DEP_OpenMesh_GIT_TAG                "OpenMesh-11.0")
  set(AV_DEP_OpenMesh_EXTRA_CMAKE_FLAGS
    -DBLOCK_IN_SOURCE_BUILD=OFF
    -DDISABLE_QMAKE_BUILD=ON
    -DOPENMESH_BUILD_SHARED=${BUILD_SHARED_LIBS}
    -DBUILD_APPS=OFF
    -DOPENMESH_DOCS=OFF
    ${AV_DEP_OpenMesh_XL_XCODE_FIX}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenMesh_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenMesh...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(OpenMesh GIT_REPO ${AV_DEP_OpenMesh_GIT_REPO} GIT_TAG "${AV_DEP_OpenMesh_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(OpenMesh
    EXTRA_CMAKE_ARGS ${AV_DEP_OpenMesh_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenMesh()
