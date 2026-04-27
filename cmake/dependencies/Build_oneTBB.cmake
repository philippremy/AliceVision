#
# Build_oneTBB.cmake
#
# Builds an embedded version of oneTBB

include(AV_ColoredMessage)

function(build_oneTBB)

  set(AV_DEP_oneTBB_VERSION           "2022.3.0")
  set(AV_DEP_oneTBB_URL               "https://github.com/uxlfoundation/oneTBB/archive/refs/tags/v${AV_DEP_oneTBB_VERSION}.tar.gz")
  set(AV_DEP_oneTBB_HASH              "SHA256=01598a46c1162c27253a0de0236f520fd8ee8166e9ebb84a4243574f88e6e50a")
  set(AV_DEP_oneTBB_EXTRA_CMAKE_FLAGS
    -DTBB_TEST=OFF
    -DTBB_EXAMPLES=OFF
    -DTBB_STRICT=OFF
    -DTBB_WINDOWS_DRIVER=OFF
    -DTBB_NO_APPCONTAINER=OFF
    -DTBB4PY_BUILD=OFF
    -DTBB_BUILD=ON
    -DTBBMALLOC_BUILD=ON
    -DTBBMALLOC_PROXY_BUILD=ON
    -DTBB_CPF=OFF
    -DTBB_FIND_PACKAGE=OFF
    -DTBB_DISABLE_HWLOC_AUTOMATIC_SEARCH=OFF
    -DTBB_ENABLE_IPO=${AV_BUILD_WITH_LTO}
    -DTBB_CONTROL_FLOW_GUARD=OFF
    -DTBB_FUZZ_TESTING=OFF
    -DTBB_INSTALL=ON
    -DTBB_FILE_TRIM=ON
    -DTBB_LINUX_SEPARATE_DBG=OFF
    -DTBB_BUILD_APPLE_FRAMEWORKS=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_oneTBB_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of oneTBB...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(oneTBB URL ${AV_DEP_oneTBB_URL} URL_HASH "${AV_DEP_oneTBB_HASH}")

  # Build the dependency
  av_build_cmake_dependency(oneTBB
    EXTRA_CMAKE_ARGS ${AV_DEP_oneTBB_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_oneTBB()
