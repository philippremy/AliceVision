#
# Build_brotli.cmake
#
# Builds an embedded version of brotli

include(AV_ColoredMessage)

function(build_brotli)

  set(AV_DEP_brotli_VERSION           "1.2.0")
  set(AV_DEP_brotli_URL               "https://github.com/google/brotli/archive/refs/tags/v${AV_DEP_brotli_VERSION}.tar.gz")
  set(AV_DEP_brotli_HASH              "SHA256=816c96e8e8f193b40151dad7e8ff37b1221d019dbcb9c35cd3fadbfe6477dfec")
  set(AV_DEP_brotli_EXTRA_CMAKE_FLAGS
    -DBROTLI_BUILD_TOOLS=OFF
    -DBROTLI_BUILD_FOR_PACKAGE=OFF
    -DBROTLI_DISABLE_TESTS=ON
    -DBROTLI_BUNDLED_MODE=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_brotli_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of brotli...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(brotli URL ${AV_DEP_brotli_URL} URL_HASH "${AV_DEP_brotli_HASH}")

  # Build the dependency
  av_build_cmake_dependency(brotli
    EXTRA_CMAKE_ARGS ${AV_DEP_brotli_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_brotli()
