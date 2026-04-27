#
# Build_Assimp.cmake
#
# Builds an embedded version of Assimp

include(AV_ColoredMessage)

function(build_Assimp)

  set(AV_DEP_Assimp_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_Assimp_BUILD_STATIC ON)
  endif()

  set(AV_DEP_Assimp_VERSION           "6.0.4")
  set(AV_DEP_Assimp_URL               "https://github.com/assimp/assimp/archive/refs/tags/v${AV_DEP_Assimp_VERSION}.tar.gz")
  set(AV_DEP_Assimp_HASH              "SHA256=afa5487efdd285661afa842c85187cd8c541edad92e8d4aa85be4fca7476eccc")
  set(AV_DEP_Assimp_EXTRA_CMAKE_FLAGS
    -DASSIMP_BUILD_M3D_IMPORTER=OFF
    -DASSIMP_BUILD_M3D_EXPORTER=OFF
    -DASSIMP_BUILD_USD_IMPORTER=OFF
    -DASSIMP_BUILD_USD_VERBOSE_LOGS=OFF
    -DASSIMP_BUILD_VRML_IMPORTER=OFF
    -DASSIMP_HUNTER_ENABLED=OFF
    -DASSIMP_BUILD_FRAMEWORK=OFF
    -DASSIMP_DOUBLE_PRECISION=OFF
    -DASSIMP_OPT_BUILD_PACKAGES=OFF
    -DASSIMP_ANDROID_JNIIOSYSTEM=OFF
    -DASSIMP_NO_EXPORT=OFF
    -DASSIMP_BUILD_ASSIMP_TOOLS=OFF
    -DASSIMP_BUILD_SAMPLES=OFF
    -DASSIMP_BUILD_TESTS=OFF
    -DASSIMP_COVERALLS=OFF
    -DASSIMP_INSTALL=ON
    -DASSIMP_WARNINGS_AS_ERRORS=OFF
    -DASSIMP_ASAN=OFF
    -DASSIMP_UBSAN=OFF
    -DASSIMP_BUILD_DOCS=OFF
    -DASSIMP_INJECT_DEBUG_POSTFIX=ON
    -DASSIMP_IGNORE_GIT_HASH=OFF
    -DASSIMP_BUILD_ZLIB=OFF   # Even on Windows we can provide our own zlib
    -DASSIMP_BUILD_SAMPLES=OFF
    -DASSIMP_BUILD_DRACO=OFF
    -DASSIMP_BUILD_ASSIMP_VIEW=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Assimp_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Assimp...")
    return()
  endif()

  # Assimp fails to link in zlib, so pass it by default
  # On macOS, we just hard-link libPNG, zlib and OpenMP
  if(APPLE)
    # Must add the install prefix as linker search path (for OpenMP and PNG)
    set(AV_DEP_Assimp_ADD_LDFLAGS -DCMAKE_SHARED_LINKER_FLAGS=-Wl,-L${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
    string(APPEND AV_DEP_Assimp_ADD_LDFLAGS ",-lz")  # For zlib
    list(APPEND AV_DEP_Assimp_EXTRA_CMAKE_FLAGS ${AV_DEP_Assimp_ADD_LDFLAGS})
  endif()

  # Make the target available
  av_make_dependency_available(Assimp URL ${AV_DEP_Assimp_URL} URL_HASH "${AV_DEP_Assimp_HASH}")

  # Build the dependency
  av_build_cmake_dependency(Assimp
    EXTRA_CMAKE_ARGS ${AV_DEP_Assimp_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Assimp()
