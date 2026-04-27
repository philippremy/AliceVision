#
# Build_lz4.cmake
#
# Builds an embedded version of lz4

include(AV_ColoredMessage)

function(build_lz4)

  set(AV_DEP_lz4_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_lz4_BUILD_STATIC ON)
  endif()

  set(AV_DEP_lz4_VERSION           "1.10.0")
  set(AV_DEP_lz4_URL               "https://github.com/lz4/lz4/releases/download/v${AV_DEP_lz4_VERSION}/lz4-${AV_DEP_lz4_VERSION}.tar.gz")
  set(AV_DEP_lz4_HASH              "SHA256=537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b")
  set(AV_DEP_lz4_EXTRA_CMAKE_FLAGS
    -DLZ4_BUILD_CLI=OFF
    -DLZ4_BUILD_LEGACY_LZ4C=OFF
    -DBUILD_STATIC_LIBS=${AV_DEP_lz4_BUILD_STATIC}
    -DLZ4_POSITION_INDEPENDENT_LIB=ON
  )

  # Return early if the dependency should not be built
  if(AV_DEP_lz4_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of lz4...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(lz4 URL ${AV_DEP_lz4_URL} URL_HASH "${AV_DEP_lz4_HASH}")

  # Build the dependency
  # SPECIAL: OpenMP is in the source directory "<LZ4_ROOT>/build/cmake"
  av_build_cmake_dependency(lz4
    SPECIAL_SOURCE_DIR "./build/cmake"
    EXTRA_CMAKE_ARGS ${AV_DEP_lz4_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_lz4()
