#
# Build_OpenImageIO.cmake
#
# Builds an embedded version of OpenImageIO

include(AV_ColoredMessage)

function(build_OpenImageIO)

  set(AV_DEP_OpenImageIO_CODEC_ARGS)
  if(AV_USE_IMAGE_CODECS MATCHES "JPEG-XL")
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_JXL=ON)
  else()
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_JXL=OFF)
  endif()
  # All others are should only be explicitly *dis*abled
  if(NOT AV_USE_OPENCV)
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_OpenCV=OFF)
  endif()
  if(NOT AV_USE_IMAGE_CODECS MATCHES "PNG")
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_PNG=OFF)
  endif()
  if(NOT AV_USE_IMAGE_CODECS MATCHES "GIF")
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_GIF=OFF)
  endif()
  if(NOT AV_USE_IMAGE_CODECS MATCHES "RAW")
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_Libraw=OFF)
  endif()
  if(NOT AV_USE_IMAGE_CODECS MATCHES "OpenJPEG")
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_OpenJPEG=OFF)
  endif()
  if(NOT AV_USE_IMAGE_CODECS MATCHES "WebP")
    list(APPEND AV_DEP_OpenImageIO_CODEC_ARGS -DUSE_WebP=OFF)
  endif()

  set(AV_DEP_OpenImageIO_VERSION           "3.1.12.0")
  set(AV_DEP_OpenImageIO_URL               "https://github.com/AcademySoftwareFoundation/OpenImageIO/releases/download/v${AV_DEP_OpenImageIO_VERSION}/OpenImageIO-${AV_DEP_OpenImageIO_VERSION}.tar.gz")
  set(AV_DEP_OpenImageIO_HASH              "SHA256=704511376faf32767cdcd9aa9a6d0be2b03b91f849ad9008227dc9f0e14bc265")
  set(AV_DEP_OpenImageIO_EXTRA_CMAKE_FLAGS
    -DCMAKE_USE_FOLDERS=OFF
    -DVERBOSE=OFF
    -DOIIO_BUILD_TOOLS=OFF
    -DOIIO_BUILD_TESTS=OFF
    -DOIIO_USE_HWY=ON
    -DBUILD_OIIOUTIL_ONLY=OFF
    -DBUILD_DOCS=OFF
    -DINSTALL_DOCS=OFF
    -DINSTALL_FONTS=OFF
    -DEMBEDPLUGINS=ON
    -DOIIO_THREAD_ALLOW_DCLP=ON
    -DIGNORE_HOMEBREWED_DEPS=${AV_NO_SYSTEM_DEPS}
    -DUSE_R3DSDK=OFF
    -DUSE_QT=OFF
    -DUSE_libuhdr=OFF
    -DUSE_EXTERNAL_PUGIXML=OFF
    -DUSE_Freetype=OFF
    -DUSE_DCMTK=OFF
    -DUSE_FFmpeg=OFF  # FIXME: Update
    -DUSE_Libheif=OFF # FIXME: Add libheif for the future?
    -DUSE_OpenVDB=OFF
    -DUSE_Ptex=OFF
    -DUSE_Nuke=OFF
    -DUSE_PYTHON=OFF
    -DPYLIB_INCLUDE_SONAME=OFF
    -DOIIO_USE_CUDA=${AV_USE_CUDA}
    ${AV_DEP_OpenImageIO_CODEC_ARGS}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_OpenImageIO_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of OpenImageIO...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(OpenImageIO URL ${AV_DEP_OpenImageIO_URL} URL_HASH "${AV_DEP_OpenImageIO_HASH}")

  # Build the dependency
  av_build_cmake_dependency(OpenImageIO
    EXTRA_CMAKE_ARGS ${AV_DEP_OpenImageIO_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_OpenImageIO()
