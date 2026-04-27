#
# Build_OpenJPEG.cmake
#
# Builds an embedded version of OpenJPEG

include(AV_ColoredMessage)

function(build_OpenJPEG)

  set(AV_DEP_OpenJPEG_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_OpenJPEG_BUILD_STATIC ON)
  endif()

  set(AV_DEP_OpenJPEG_VERSION           "2.5.4")
  set(AV_DEP_OpenJPEG_URL               "https://github.com/uclouvain/openjpeg/archive/refs/tags/v${AV_DEP_OpenJPEG_VERSION}.tar.gz")
  set(AV_DEP_OpenJPEG_HASH              "SHA256=a695fbe19c0165f295a8531b1e4e855cd94d0875d2f88ec4b61080677e27188a")
  set(AV_DEP_OpenJPEG_EXTRA_CMAKE_FLAGS
    -DBUILD_DOC=OFF
    -DBUILD_STATIC_LIBS=${AV_DEP_OpenJPEG_BUILD_STATIC}
    -DBUILD_LUTS_GENERATOR=OFF
    -DBUILD_UNIT_TESTS=OFF
    -DBUILD_CODEC=OFF
    -DBUILD_JPIP=OFF
    -DBUILD_JPIP_SERVER=OFF
    -DBUILD_VIEWER=OFF
    -DBUILD_JAVA=OFF
    -DBUILD_THIRDPARTY=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenJPEG_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenJPEG...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(OpenJPEG URL ${AV_DEP_OpenJPEG_URL} URL_HASH "${AV_DEP_OpenJPEG_HASH}")

  # Build the dependency
  av_build_cmake_dependency(OpenJPEG
    EXTRA_CMAKE_ARGS ${AV_DEP_OpenJPEG_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenJPEG()
