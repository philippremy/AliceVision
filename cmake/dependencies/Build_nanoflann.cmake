#
# Build_nanoflann.cmake
#
# Builds an embedded version of nanoflann

include(AV_ColoredMessage)

function(build_nanoflann)

  set(AV_DEP_nanoflann_VERSION           "1.9.0")
  set(AV_DEP_nanoflann_URL               "https://github.com/jlblancoc/nanoflann/archive/refs/tags/v${AV_DEP_nanoflann_VERSION}.tar.gz")
  set(AV_DEP_nanoflann_HASH              "SHA256=14dc863ec47d52ec3272b4fd409fd198a52e6cab58ece70b1da9c3dc2e478942")
  set(AV_DEP_nanoflann_EXTRA_CMAKE_FLAGS
    -DNANOFLANN_BUILD_EXAMPLES=OFF
    -DNANOFLANN_BUILD_TESTS=OFF
    -DNANOFLANN_USE_SYSTEM_GTEST=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_nanoflann_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of nanoflann...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(nanoflann URL ${AV_DEP_nanoflann_URL} URL_HASH "${AV_DEP_nanoflann_HASH}")

  # Build the dependency
  av_build_cmake_dependency(nanoflann
    EXTRA_CMAKE_ARGS ${AV_DEP_nanoflann_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_nanoflann()
