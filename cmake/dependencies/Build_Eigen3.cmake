#
# Build_Eigen3.cmake
#
# Builds an embedded version of Eigen3

include(AV_ColoredMessage)

function(build_Eigen3)

  set(AV_DEP_Eigen3_VERSION           "3.4.1")
  set(AV_DEP_Eigen3_URL               "https://gitlab.com/libeigen/eigen/-/archive/${AV_DEP_Eigen3_VERSION}/eigen-${AV_DEP_Eigen3_VERSION}.tar.bz2")
  set(AV_DEP_Eigen3_HASH              "SHA256=8bb7280b7551bf06418d11a9671fdf998cb927830cf21589b394382d26779821")
  set(AV_DEP_Eigen3_EXTRA_CMAKE_FLAGS
    -DEIGEN_BUILD_BLAS=OFF
    -DEIGEN_BUILD_LAPACK=OFF
    -DBUILD_TESTING=OFF
    -DEIGEN_BUILD_TESTING=OFF
    -DEIGEN_LEAVE_TEST_IN_ALL_TARGET=OFF
    -DEIGEN_BUILD_BTL=OFF
    -DEIGEN_BUILD_SPBENCH=OFF
    -DEIGEN_BUILD_DOC_DEFAULT=OFF
    -DEIGEN_BUILD_DOC=OFF
    -DEIGEN_BUILD_DEMOS=OFF
    -DEIGEN_BUILD_PKGCONFIG=OFF
    -DEIGEN_BUILD_CMAKE_PACKAGE=ON
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Eigen3_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Eigen3...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(Eigen3 URL ${AV_DEP_Eigen3_URL} URL_HASH "${AV_DEP_Eigen3_HASH}")

  # Build the dependency
  av_build_cmake_dependency(Eigen3
    EXTRA_CMAKE_ARGS ${AV_DEP_Eigen3_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Eigen3()
