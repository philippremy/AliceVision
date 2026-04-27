#
# Build_CCTag.cmake
#
# Builds an embedded version of CCTag

include(AV_ColoredMessage)

function(build_CCTag)

  set(AV_DEP_CCTag_USE_AVX2 OFF)
  if(USE_AVX2)
    set(AV_DEP_CCTag_USE_AVX2 ON)
  endif()

  set(AV_DEP_CCTag_GIT_REPO          "https://github.com/alicevision/cctag")
  set(AV_DEP_CCTag_GIT_TAG           "develop")
  set(AV_DEP_CCTag_EXTRA_CMAKE_FLAGS
    -DCCTAG_SERIALIZE=OFF
    -DCCTAG_VISUAL_DEBUG=OFF
    -DCCTAG_NO_COUT=ON
    -DCCTAG_WITH_CUDA=${AV_USE_CUDA}
    -DCCTAG_BUILD_APPS=OFF
    -DCCTAG_CUDA_CC_CURRENT_ONLY=OFF
    -DCCTAG_NVCC_WARNINGS=OFF
    -DCCTAG_EIGEN_MEMORY_ALIGNMENT=ON
    -DCCTAG_USE_POSITION_INDEPENDENT_CODE=ON
    -DCCTAG_ENABLE_SIMD_AVX2=${AV_DEP_CCTag_USE_AVX2}
    -DCCTAG_BUILD_TESTS=OFF
    -DCCTAG_BUILD_DOC=OFF
    -DCCTAG_NO_THRUST_COPY_IF=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_CCTag_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of CCTag...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(CCTag GIT_REPO ${AV_DEP_CCTag_GIT_REPO} GIT_TAG "${AV_DEP_CCTag_GIT_TAG}")

  # Build the dependency
  av_build_cmake_dependency(CCTag
    EXTRA_CMAKE_ARGS ${AV_DEP_CCTag_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_CCTag()
