#
# Build_SuiteSparse.cmake
#
# Builds an embedded version of SuiteSparse

include(AV_ColoredMessage)

function(build_SuiteSparse)

  set(AV_DEP_SuiteSparse_BUILD_STATIC_LIBS ON)
  if(BUILD_SHARED_LIBS)
    set(AV_DEP_SuiteSparse_BUILD_STATIC_LIBS OFF)
  endif()

  set(AV_DEP_SuiteSparse_COMPONENTS
    suitesparse_config
    camd
    cholmod
    ccolamd
    colamd
    spqr
  )
  # Join into list with EXTRA_CMAKE_ARGS syntax
  list(JOIN AV_DEP_SuiteSparse_COMPONENTS "|" AV_DEP_SuiteSparse_COMPONENTS_JOINED)

  set(AV_DEP_SuiteSparse_VERSION           "7.12.2")
  set(AV_DEP_SuiteSparse_URL               "https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/refs/tags/v${AV_DEP_SuiteSparse_VERSION}.tar.gz")
  set(AV_DEP_SuiteSparse_HASH              "SHA256=679412daa5f69af96d6976595c1ac64f252287a56e98cc4a8155d09cc7fd69e8")
  set(AV_DEP_SuiteSparse_EXTRA_CMAKE_FLAGS
    -DSUITESPARSE_ENABLE_PROJECTS=${AV_DEP_SuiteSparse_COMPONENTS_JOINED}
    -DSUITESPARSE_USE_SYSTEM_BTF=OFF
    -DSUITESPARSE_USE_SYSTEM_CHOLMOD=OFF
    -DSUITESPARSE_USE_SYSTEM_AMD=OFF
    -DSUITESPARSE_USE_SYSTEM_COLAMD=OFF
    -DSUITESPARSE_USE_SYSTEM_CAMD=OFF
    -DSUITESPARSE_USE_SYSTEM_CCOLAMD=OFF
    -DSUITESPARSE_USE_SYSTEM_GRAPHBLAS=OFF
    -DSUITESPARSE_USE_SYSTEM_SUITESPARSE_CONFIG=OFF
    -DSUITESPARSE_USE_SYSTEM_UMFPACK=OFF
    -DSUITESPARSE_DEMOS=OFF
    -DSUITESPARSE_USE_CUDA=${AV_USE_CUDA}
    -DBUILD_STATIC_LIBS=${AV_DEP_SuiteSparse_BUILD_STATIC_LIBS}
    -DBLA_STATIC=${AV_DEP_SuiteSparse_BUILD_STATIC_LIBS}
    -DSUITESPARSE_USE_FORTRAN=OFF
    -DSUITESPARSE_USE_STRICT=OFF
    -DSUITESPARSE_CONFIG_USE_OPENMP=${AV_USE_OPENMP}
    -DCHOLMOD_USE_CUDA=${AV_USE_CUDA}
    -DCHOLMOD_USE_OPENMP=${AV_USE_OPENMP}
    -DCHOLMOD_CHECK=ON
    -DCHOLMOD_MATRIXOPS=ON
    -DCHOLMOD_CHOLESKY=ON
    -DCHOLMOD_MODIFY=ON
    -DCHOLMOD_CAMD=ON
    -DCHOLMOD_PARTITION=ON
    -DCHOLMOD_SUPERNODAL=ON
    -DSPQR_USE_CUDA=${AV_USE_CUDA}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_SuiteSparse_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of SuiteSparse...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(SuiteSparse URL ${AV_DEP_SuiteSparse_URL} URL_HASH "${AV_DEP_SuiteSparse_HASH}")

  # Build the dependency
  av_build_cmake_dependency(SuiteSparse
    EXTRA_CMAKE_ARGS ${AV_DEP_SuiteSparse_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_SuiteSparse()
