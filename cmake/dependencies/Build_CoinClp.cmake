#
# Build_CoinClp.cmake
#
# Builds an embedded version of CoinClp

include(AV_ColoredMessage)

function(build_CoinClp)

  set(AV_DEP_CoinClp_GIT_REPO            "https://github.com/philippremy/Clp")
  set(AV_DEP_CoinClp_GIT_TAG             "develop")
  set(AV_DEP_CoinClp_EXTRA_CMAKE_FLAGS)

  # Return early if the dependency should not be built
  if(AV_DEP_CoinClp_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of CoinClp...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(CoinClp GIT_REPO ${AV_DEP_CoinClp_GIT_REPO} GIT_TAG "${AV_DEP_CoinClp_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(CoinClp)

endfunction()

# Invoke the function automatically
build_CoinClp()
