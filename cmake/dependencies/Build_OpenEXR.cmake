#
# Build_OpenEXR.cmake
#
# Builds an embedded version of OpenEXR

include(AV_ColoredMessage)

function(build_OpenEXR)

  set(AV_DEP_OpenEXR_VERSION           "3.4.10")
  set(AV_DEP_OpenEXR_URL               "https://github.com/AcademySoftwareFoundation/openexr/releases/download/v${AV_DEP_OpenEXR_VERSION}/openexr-${AV_DEP_OpenEXR_VERSION}.tar.gz")
  set(AV_DEP_OpenEXR_HASH              "SHA256=2e054a8f5030c25d1585cbfa537feaaf86d69388b75c00d96c3a91f676e88cbe")
  set(AV_DEP_OpenEXR_EXTRA_CMAKE_FLAGS
    -DOPENEXR_INSTALL_DOCS=OFF
    -DBUILD_WEBSITE=OFF
    -DOPENEXR_INSTALL_PKG_CONFIG=ON
    -DOPENEXR_ENABLE_THREADING=ON
    -DOPENEXR_USE_TBB=ON
    -DOPENEXR_USE_DEFAULT_VISIBILITY=OFF
    -DOPENEXR_ENABLE_LARGE_STACK=ON
    -DOPENEXR_INSTALL=ON
    -DOPENEXR_BUILD_LIBS=ON
    -DOPENEXR_BUILD_TOOLS=OFF
    -DOPENEXR_INSTALL_TOOLS=OFF
    -DOPENEXR_INSTALL_DEVELOPER_TOOLS=OFF
    -DOPENEXR_BUILD_EXAMPLES=OFF
    -DOPENEXR_BUILD_PYTHON=OFF
    -DOPENEXR_BUILD_OSS_FUZZ=OFF
    -DOPENEXR_TEST_LIBRARIES=OFF
    -DOPENEXR_TEST_TOOLS=OFF
    -DOPENEXR_TEST_PYTHON=OFF
    -DOPENEXR_FORCE_INTERNAL_DEFLATE=ON # Because libdeflate is not needed by anything else, let OpenEXR build it
    -DOPENEXR_FORCE_INTERNAL_OPENJPH=OFF # We always have OpenJPH being built, so use this specific one
    -DOPENEXR_FORCE_INTERNAL_IMATH=OFF  # We always have a Imath being built, so use this specific one
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenEXR_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenEXR...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(OpenEXR URL ${AV_DEP_OpenEXR_URL} URL_HASH "${AV_DEP_OpenEXR_HASH}")

  # Build the dependency
  av_build_cmake_dependency(OpenEXR
    EXTRA_CMAKE_ARGS ${AV_DEP_OpenEXR_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenEXR()
