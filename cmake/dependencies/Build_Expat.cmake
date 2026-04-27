#
# Build_Expat.cmake
#
# Builds an embedded version of Expat

include(AV_ColoredMessage)

function(build_Expat)

  set(AV_DEP_Expat_VERSION           "2.7.5")
  set(AV_DEP_Expat_VERSION_US        "2_7_5")
  set(AV_DEP_Expat_URL               "https://github.com/libexpat/libexpat/releases/download/R_${AV_DEP_Expat_VERSION_US}/expat-${AV_DEP_Expat_VERSION}.tar.xz")
  set(AV_DEP_Expat_HASH              "SHA256=1032dfef4ff17f70464827daa28369b20f6584d108bc36f17ab1676e1edd2f91")
  set(AV_DEP_Expat_EXTRA_CMAKE_FLAGS
    -DEXPAT_BUILD_TOOLS=OFF
    -DEXPAT_BUILD_EXAMPLES=OFF
    -DEXPAT_BUILD_TESTS=OFF
    -DEXPAT_SHARED_LIBS=${BUILD_SHARED_LIBS}
    -DEXPAT_BUILD_DOCS=OFF
    -DEXPAT_BUILD_FUZZERS=OFF
    -DEXPAT_BUILD_PKGCONFIG=ON
    -DEXPAT_OSSFUZZ_BUILD=OFF
    -DEXPAT_ENABLE_INSTALL=ON
    -DEXPAT_SYMBOL_VERSIONING=OFF
    -DEXPAT_DTD=ON
    -DEXPAT_GE=ON
    -DEXPAT_NS=ON
    -DEXPAT_WARNINGS_AS_ERRORS=OFF
    -DEXPAT_ATTR_INFO=OFF
    -DEXPAT_LARGE_SIZE=OFF
    -DEXPAT_MIN_SIZE=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Expat_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Expat...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(Expat URL ${AV_DEP_Expat_URL} URL_HASH "${AV_DEP_Expat_HASH}")

  # Build the dependency
  av_build_cmake_dependency(Expat
    EXTRA_CMAKE_ARGS ${AV_DEP_Expat_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Expat()
