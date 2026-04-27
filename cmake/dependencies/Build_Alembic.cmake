#
# Build_Alembic.cmake
#
# Builds an embedded version of Alembic

include(AV_ColoredMessage)

function(build_Alembic)

  set(AV_DEP_Alembic_BUILD_STATIC_DEPS ON)
  if(BUILD_SHARED_LIBS)
    set(AV_DEP_Alembic_BUILD_STATIC_DEPS OFF)
  endif()

  set(AV_DEP_Alembic_VERSION           "1.8.11")
  set(AV_DEP_Alembic_URL               "https://github.com/alembic/alembic/archive/refs/tags/${AV_DEP_Alembic_VERSION}.tar.gz")
  set(AV_DEP_Alembic_HASH              "SHA256=ab299bb4b1894a6675c73fa29940522b54c81a91b1d691ca3470d86b7345ffce")
  set(AV_DEP_Alembic_EXTRA_CMAKE_FLAGS
    -DUSE_ARNOLD=OFF
    -DUSE_BINARIES=OFF
    -DUSE_EXAMPLES=OFF
    -DUSE_HDF5=OFF
    -DUSE_MAYA=OFF
    -DUSE_PRMAN=OFF
    -DUSE_PYALEMBIC=OFF
    -DUSE_STATIC_BOOST=${AV_DEP_Alembic_BUILD_STATIC_DEPS}
    -DUSE_STATIC_HDF5=${AV_DEP_Alembic_BUILD_STATIC_DEPS}
    -DUSE_TESTS=OFF
    -DALEMBIC_BUILD_LIBS=ON
    -DALEMBIC_SHARED_LIBS=${BUILD_SHARED_LIBS}
    -DALEMBIC_DEBUG_WARNINGS_AS_ERRORS=OFF
    -DDOCS_PATH=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Alembic_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Alembic...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(Alembic URL ${AV_DEP_Alembic_URL} URL_HASH "${AV_DEP_Alembic_HASH}")

  # Build the dependency
  av_build_cmake_dependency(Alembic
    EXTRA_CMAKE_ARGS ${AV_DEP_Alembic_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Alembic()
