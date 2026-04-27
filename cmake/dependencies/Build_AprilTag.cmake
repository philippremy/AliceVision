#
# Build_AprilTag.cmake
#
# Builds an embedded version of AprilTag

include(AV_ColoredMessage)

function(build_AprilTag)

  # FIXME: Remove when we don't need to pass manual linker flags anymore
  if(${CMAKE_GENERATOR} STREQUAL "Xcode")
    set(AV_DEP_AprilTag_XL_XCODE_FIX -G "Unix Makefiles")
  endif()

  set(AV_DEP_AprilTag_VERSION           "3.4.5")
  set(AV_DEP_AprilTag_URL               "https://github.com/AprilRobotics/apriltag/archive/refs/tags/v${AV_DEP_AprilTag_VERSION}.tar.gz")
  set(AV_DEP_AprilTag_HASH              "SHA256=3749f48220db78c29c375a373861f4e1f4138e5dbae3c298584e96cfcc556515")
  set(AV_DEP_AprilTag_EXTRA_CMAKE_FLAGS
    -DBUILD_EXAMPLES=OFF
    -DASAN=OFF
    -DBUILD_PYTHON_WRAPPER=OFF
    ${AV_DEP_AprilTag_XL_XCODE_FIX}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_AprilTag_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of AprilTag...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(AprilTag URL ${AV_DEP_AprilTag_URL} URL_HASH "${AV_DEP_AprilTag_HASH}")

  # Build the dependency
  av_build_cmake_dependency(AprilTag
    EXTRA_CMAKE_ARGS ${AV_DEP_AprilTag_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_AprilTag()
