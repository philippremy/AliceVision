#
# Build_OpenSubdiv.cmake
#
# Builds an embedded version of OpenSubdiv

include(AV_ColoredMessage)

function(build_OpenSubdiv)

  set(AV_DEP_OpenSubdiv_DISABLE_OPENMP ON)
  if(AV_USE_OPENMP)
    set(AV_DEP_OpenSubdiv_DISABLE_OPENMP OFF)
  endif()

  set(AV_DEP_OpenSubdiv_DISABLE_CUDA ON)
  if(AV_USE_CUDA)
    set(AV_DEP_OpenSubdiv_DISABLE_CUDA OFF)
  endif()

  set(AV_DEP_OpenSubdiv_VERSION           "3_7_0")
  set(AV_DEP_OpenSubdiv_URL               "https://github.com/PixarAnimationStudios/OpenSubdiv/archive/refs/tags/v${AV_DEP_OpenSubdiv_VERSION}.tar.gz")
  set(AV_DEP_OpenSubdiv_HASH              "SHA256=f843eb49daf20264007d807cbc64516a1fed9cdb1149aaf84ff47691d97491f9")
  set(AV_DEP_OpenSubdiv_EXTRA_CMAKE_FLAGS
    -DNO_LIB=OFF
    -DNO_EXAMPLES=ON
    -DNO_TUTORIALS=ON
    -DNO_REGRESSION=ON
    -DNO_PTEX=ON
    -DNO_DOC=ON
    -DNO_OMP=${AV_DEP_OpenSubdiv_DISABLE_OPENMP}
    -DNO_TBB=OFF  # Always enable oneTBB
    -DNO_CUDA=${AV_DEP_OpenSubdiv_DISABLE_CUDA}
    -DNO_OPENCL=ON
    -DNO_CLEW=ON
    -DNO_OPENGL=ON
    -DNO_METAL=ON
    -DNO_DX=ON
    -DNO_TESTS=ON
    -DNO_GLTESTS=ON
    -DNO_GLEW=ON
    -DNO_GLFW=ON
    -DNO_GLFW_X11=ON
    -DNO_MACOS_FRAMEWORK=ON
    -DOSD_PATCH_SHADER_SOURCE_GLSL=OFF
    -DOSD_PATCH_SHADER_SOURCE_HLSL=OFF
    -DOSD_PATCH_SHADER_SOURCE_MSL=OFF
    -DOPENSUBDIV_GREGORY_EVAL_TRUE_DERIVATIVE=OFF
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenSubdiv_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenSubdiv...")
    return()
  endif()

  # OpenSubdiv does not link to libomp on Apple correctly
  # Hardlink the library
  if(APPLE)
    if(AV_USE_OPENMP)
      set(AV_DEP_OpenSubdiv_ADD_LDFLAGS -DCMAKE_SHARED_LINKER_FLAGS=-Wl,-L${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
      string(APPEND AV_DEP_OpenSubdiv_ADD_LDFLAGS ",-lomp")  # For OpenMP
    endif()
    list(APPEND AV_DEP_OpenSubdiv_EXTRA_CMAKE_FLAGS ${AV_DEP_OpenSubdiv_ADD_LDFLAGS})
  endif()

  # Make the target available
  av_make_dependency_available(OpenSubdiv URL ${AV_DEP_OpenSubdiv_URL} URL_HASH "${AV_DEP_OpenSubdiv_HASH}")

  # Build the dependency
  av_build_cmake_dependency(OpenSubdiv
    EXTRA_CMAKE_ARGS ${AV_DEP_OpenSubdiv_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenSubdiv()
