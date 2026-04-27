#
# Build_OpenMP.cmake
#
# Builds an embedded version of LLVM OpenMP

include(AV_ColoredMessage)

function(build_OpenMP)

  set(AV_DEP_OPENMP_VERSION           "22.1.4")
  set(AV_DEP_OPENMP_URL               "https://github.com/llvm/llvm-project/releases/download/llvmorg-${AV_DEP_OPENMP_VERSION}/llvm-project-${AV_DEP_OPENMP_VERSION}.src.tar.xz")
  set(AV_DEP_OPENMP_HASH              "SHA256=3e68c90dda630c27d41d201e37b8bbf5222e39b273dec5ca880709c69e0a07d4")
  set(AV_DEP_OPENMP_EXTRA_CMAKE_FLAGS
    -DOPENMP_ENABLE_OMPT_TOOLS=OFF
    -DLIBOMP_ENABLE_SHARED=${BUILD_SHARED_LIBS}
    -DLIBOMP_LIB_TYPE=normal
    -DLIBOMP_STATS=OFF
    -DLIBOMP_USE_DEBUGGER=OFF
    -DLIBOMP_USE_HWLOC=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenMP_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenMP...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(OpenMP URL ${AV_DEP_OPENMP_URL} URL_HASH "${AV_DEP_OPENMP_HASH}")

  # Build the dependency
  # SPECIAL: OpenMP is in the source directory "<LLVM_ROOT>/openmp"
  av_build_cmake_dependency(OpenMP
    SPECIAL_SOURCE_DIR "./openmp"
    EXTRA_CMAKE_ARGS ${AV_DEP_OPENMP_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenMP()
