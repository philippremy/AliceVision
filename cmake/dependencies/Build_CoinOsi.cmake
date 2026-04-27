#
# Build_CoinOsi.cmake
#
# Builds an embedded version of CoinOsi

include(AV_ColoredMessage)

function(build_CoinOsi)

  if(DEFINED AV_MOSEK_DIR)
    set(AV_DEP_CoinOsi_MOSEK_FLAG -DAV_MOSEK_DIR=${AV_MOSEK_DIR})
  endif()

  set(AV_DEP_CoinOsi_GIT_REPO            "https://github.com/philippremy/Osi")
  set(AV_DEP_CoinOsi_GIT_TAG             "develop")
  set(AV_DEP_CoinOsi_EXTRA_CMAKE_FLAGS
    ${AV_DEP_CoinOsi_MOSEK_FLAG}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_CoinOsi_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of CoinOsi...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(CoinOsi GIT_REPO ${AV_DEP_CoinOsi_GIT_REPO} GIT_TAG "${AV_DEP_CoinOsi_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(CoinOsi
    EXTRA_CMAKE_ARGS ${AV_DEP_CoinOsi_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_CoinOsi()
