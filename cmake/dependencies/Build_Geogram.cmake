#
# Build_Geogram.cmake
#
# Builds an embedded version of Geogram

include(AV_ColoredMessage)

function(build_Geogram)

  # Geogram is horrendeously bad at determining the target platform, so we need
  # to explicitly pass this
  if(AV_TARGET_TRIPLE STREQUAL "aarch64-apple-darwin")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Darwin-aarch64-clang-dynamic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Darwin-aarch64-clang")
    endif()
  elseif(AV_TARGET_TRIPLE STREQUAL "x86_64-apple-darwin")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Darwin-clang-dynamic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Darwin-clang")
    endif()
  elseif(AV_TARGET_TRIPLE STREQUAL "aarch64-pc-windows-msvc")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Win-vs-dynamic-generic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Win-vs-generic")
    endif()
  elseif(AV_TARGET_TRIPLE STREQUAL "x86_64-pc-windows-msvc")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Win-vs-dynamic-generic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Win-vs-generic")
    endif()
  elseif(AV_TARGET_TRIPLE MATCHES "aarch64-pc-windows-gnu")
    set(AV_DEP_Geogram_VORPALINE_PLATFORM "Win64-gcc")
  elseif(AV_TARGET_TRIPLE MATCHES "x86_64-pc-windows-gnu")
    set(AV_DEP_Geogram_VORPALINE_PLATFORM "Win64-gcc")
  elseif(AV_TARGET_TRIPLE MATCHES "aarch64-unknown-linux-gnu")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-nonx86-gcc-dynamic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-gcc-aarch64")
    endif()
  elseif(AV_TARGET_TRIPLE MATCHES "x86_64-unknown-linux-gnu")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-gcc-dynamic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-gcc")
    endif()
  elseif(AV_TARGET_TRIPLE MATCHES "aarch64-unknown-linux-gnullvm")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-nonx86-clang-dynamic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-gcc-aarch64")
    endif()
  elseif(AV_TARGET_TRIPLE MATCHES "x86_64-unknown-linux-gnullvm")
    if(BUILD_SHARED_LIBS)
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-clang-dynamic")
    else()
      set(AV_DEP_Geogram_VORPALINE_PLATFORM "Linux64-clang")
    endif()
  endif()

  set(AV_DEP_Geogram_VERSION           "1.9.9")
  set(AV_DEP_Geogram_URL               "https://github.com/BrunoLevy/geogram/releases/download/v${AV_DEP_Geogram_VERSION}/geogram_${AV_DEP_Geogram_VERSION}.tar.gz")
  set(AV_DEP_Geogram_HASH              "SHA256=65402f3ce4b40efab178874c4ec1a8852f0ca1ab4567d72000d53efcaff52214")
  set(AV_DEP_Geogram_EXTRA_CMAKE_FLAGS
    -DGEOGRAM_WITH_GRAPHICS=OFF
    -DGEOGRAM_WITH_LEGACY_NUMERICS=OFF
    -DGEOGRAM_WITH_HLBFGS=ON
    -DGEOGRAM_WITH_TETGEN=ON
    -DGEOGRAM_WITH_TRIANGLE=ON
    -DGEOGRAM_WITH_LUA=OFF
    -DGEOGRAM_LIB_ONLY=ON
    -DGEOGRAM_WITH_FPG=ON
    -DGEOGRAM_USE_SYSTEM_GLFW3=OFF
    -DGEOGRAM_WITH_GARGANTUA=OFF
    -DGEOGRAM_WITH_TBB=OFF        # Geogram builds an embedded oneTBB, which is discouraged
    -DGEOGRAM_FOR_DEBIAN=OFF
    -DVORPALINE_PLATFORM=${AV_DEP_Geogram_VORPALINE_PLATFORM}
    -DVORPALINE_BUILD_DYNAMIC=${BUILD_SHARED_LIBS}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Geogram_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Geogram...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(Geogram URL ${AV_DEP_Geogram_URL} URL_HASH "${AV_DEP_Geogram_HASH}")

  # Build the dependency
  av_build_cmake_dependency(Geogram
    EXTRA_CMAKE_ARGS ${AV_DEP_Geogram_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Geogram()
