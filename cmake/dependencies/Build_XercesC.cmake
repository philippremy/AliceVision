#
# Build_XercesC.cmake
#
# Builds an embedded version of XercesC

include(AV_ColoredMessage)

function(build_XercesC)

  set(AV_DEP_XercesC_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_XercesC_BUILD_STATIC ON)
  endif()

  set(AV_DEP_XercesC_VERSION           "3.3.0")
  set(AV_DEP_XercesC_URL               "https://dlcdn.apache.org//xerces/c/3/sources/xerces-c-${AV_DEP_XercesC_VERSION}.tar.xz")
  set(AV_DEP_XercesC_HASH              "SHA256=a83e12af82dc4fea09c592979fdbb6f206eeaa968562d7d18a0a4dd032c51267")
  set(AV_DEP_XercesC_EXTRA_CMAKE_FLAGS)

  # Return early if the dependency should not be built
  if(AV_DEP_XercesC_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of XercesC...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(XercesC URL ${AV_DEP_XercesC_URL} URL_HASH "${AV_DEP_XercesC_HASH}")

  # Build the dependency
  av_build_cmake_dependency(XercesC)

endfunction()

# Invoke the function automatically
build_XercesC()
