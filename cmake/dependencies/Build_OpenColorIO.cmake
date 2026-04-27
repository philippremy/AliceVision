#
# Build_OpenColorIO.cmake
#
# Builds an embedded version of OpenColorIO

include(AV_ColoredMessage)

function(build_OpenColorIO)

  # INFO: OpenColorIO will build and link Yaml-Cpp, PyString and minizip-ng
  #       statically. This is (for now) intended, because I trust OpenColorIO
  #       enough to support cross-compiling these.
  #       Furthermore, they are not needed by any other dependency.

  set(AV_DEP_OpenColorIO_VERSION           "2.5.1")
  set(AV_DEP_OpenColorIO_URL               "https://github.com/AcademySoftwareFoundation/OpenColorIO/releases/download/v${AV_DEP_OpenColorIO_VERSION}/OpenColorIO-${AV_DEP_OpenColorIO_VERSION}.tar.gz")
  set(AV_DEP_OpenColorIO_HASH              "SHA256=49ab04d023d7a7a7237e24f2cfead3171b0ff7f466ce20e6e32859ec8c7cc94b")
  set(AV_DEP_OpenColorIO_EXTRA_CMAKE_FLAGS
    -DOCIO_BUILD_APPS=OFF
    -DOCIO_BUILD_OPENFX=OFF
    -DOCIO_BUILD_NUKE=OFF
    -DOCIO_BUILD_TESTS=OFF
    -DOCIO_BUILD_GPU_TESTS=OFF
    -DOCIO_USE_HEADLESS=OFF
    -DOCIO_BUILD_DOCS=OFF
    -DOCIO_BUILD_PYTHON=OFF
    -DOCIO_BUILD_JAVA=OFF
    -DOCIO_VERBOSE=OFF
    -DOCIO_USE_SOVERSION=ON
    -DOCIO_WARNING_AS_ERROR=OFF
    -DOCIO_ENABLE_SANITIZER=OFF
    -DOCIO_USE_SIMD=ON
    -DOCIO_USE_OIIO_FOR_APPS=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenColorIO_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenColorIO...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(OpenColorIO URL ${AV_DEP_OpenColorIO_URL} URL_HASH "${AV_DEP_OpenColorIO_HASH}")

  # Build the dependency
  av_build_cmake_dependency(OpenColorIO
    EXTRA_CMAKE_ARGS ${AV_DEP_OpenColorIO_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenColorIO()
