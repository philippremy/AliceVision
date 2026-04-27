#
# Build_E57Format.cmake
#
# Builds an embedded version of E57Format

include(AV_ColoredMessage)

function(build_E57Format)

  set(AV_DEP_E57Format_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_E57Format_BUILD_STATIC ON)
  endif()

  set(AV_DEP_E57Format_VERSION           "3.3.0")
  set(AV_DEP_E57Format_URL               "https://github.com/asmaloney/libE57Format/archive/refs/tags/v${AV_DEP_E57Format_VERSION}.tar.gz")
  set(AV_DEP_E57Format_HASH              "SHA256=0ba6de5c2ff6122c847867e81bf3f987b43ce4116b4949550c9cda277099e796")
  set(AV_DEP_E57Format_EXTRA_CMAKE_FLAGS
    -DE57_BUILD_SHARED=${BUILD_SHARED_LIBS}
    -DE57_VALIDATION_LEVEL=0
    -DE57_VERBOSE=OFF
    -DE57_ENABLE_DIAGNOSTIC_OUTPUT=ON
    -DE57_WRITE_CRAZY_PACKET_MODE=ON
    -DE57_RELEASE_LTO=${AV_BUILD_WITH_LTO}
    -DE57_BUILD_TEST=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_E57Format_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of E57Format...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(E57Format URL ${AV_DEP_E57Format_URL} URL_HASH "${AV_DEP_E57Format_HASH}")

  # Build the dependency
  av_build_cmake_dependency(E57Format
    EXTRA_CMAKE_ARGS ${AV_DEP_E57Format_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_E57Format()
