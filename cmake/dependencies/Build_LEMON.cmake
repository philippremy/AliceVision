#
# Build_LEMON.cmake
#
# Builds an embedded version of LEMON

include(AV_ColoredMessage)

function(build_LEMON)

  set(AV_DEP_LEMON_GIT_REPO          "https://github.com/philippremy/lemon")
  set(AV_DEP_LEMON_GIT_TAG           "develop")
  set(AV_DEP_LEMON_EXTRA_CMAKE_FLAGS
    -DLEMON_BUILD_DEMOS=OFF
    -DLEMON_BUILD_TESTS=OFF
    -DLEMON_BUILD_TOOLS=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_LEMON_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of LEMON...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(LEMON GIT_REPO ${AV_DEP_LEMON_GIT_REPO} GIT_TAG "${AV_DEP_LEMON_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(LEMON
    EXTRA_CMAKE_ARGS ${AV_DEP_LEMON_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_LEMON()
