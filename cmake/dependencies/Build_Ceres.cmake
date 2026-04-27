#
# Build_Ceres.cmake
#
# Builds an embedded version of Ceres

include(AV_ColoredMessage)

function(build_Ceres)

  set(AV_DEP_Ceres_ACCEL_ARG)
  if(AV_USE_CERES_ACCEL_SPARSE)
    if(APPLE)
      set(AV_DEP_Ceres_ACCEL_ARG -DACCELERATESPARSE=ON)
      if(NOT AV_DEP_SuiteSparse_DISABLED)
        list(APPEND AV_DEP_Ceres_ACCEL_ARG -DSUITESPARSE=ON)
      endif()
    else()
      set(AV_DEP_Ceres_ACCEL_ARG -DSUITESPARSE=ON)
    endif()
  endif()

  set(AV_DEP_Ceres_GIT_REPO          "https://github.com/ceres-solver/ceres-solver")
  set(AV_DEP_Ceres_GIT_TAG           "2.2.0")
  set(AV_DEP_Ceres_EXTRA_CMAKE_FLAGS
    ${AV_DEP_Ceres_ACCEL_ARG}
    -DUSE_CUDA=${AV_USE_CUDA}
    -DLAPACK=ON
    -DSCHUR_SPECIALIZATIONS=ON
    -DCUSTOM_BLAS=ON
    -DEIGENSPARSE=ON
    -DEIGENMETIS=ON
    -DEXPORT_BUILD_DIR=OFF
    -DBUILD_DOCUMENTATION=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_BENCHMARKS=OFF
    -DCERES_USE_SYSTEM_ABSL=OFF
    -DMINIGLOG=ON
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Ceres_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Ceres...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(Ceres GIT_REPO ${AV_DEP_Ceres_GIT_REPO} GIT_TAG "${AV_DEP_Ceres_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(Ceres
    EXTRA_CMAKE_ARGS ${AV_DEP_Ceres_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Ceres()
