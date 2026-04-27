#
# Build_CoinUtils.cmake
#
# Builds an embedded version of CoinUtils

include(AV_ColoredMessage)

function(build_CoinUtils)

  set(AV_DEP_CoinUtils_GIT_REPO            "https://github.com/philippremy/CoinUtils")
  set(AV_DEP_CoinUtils_GIT_TAG             "develop")
  set(AV_DEP_CoinUtils_EXTRA_CMAKE_FLAGS)

  # Return early if the dependency should not be built
  if(AV_DEP_CoinUtils_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of CoinUtils...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(CoinUtils GIT_REPO ${AV_DEP_CoinUtils_GIT_REPO} GIT_TAG "${AV_DEP_CoinUtils_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(CoinUtils)

endfunction()

# Invoke the function automatically
build_CoinUtils()
