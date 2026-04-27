#
# Build_zlib.cmake
#
# Builds an embedded version of zlib

include(AV_ColoredMessage)

function(build_zlib)

  set(AV_DEP_ZLIB_BUILD_STATIC OFF)
  if(NOT BUILD_SHARED_LIBS)
    set(AV_DEP_ZLIB_BUILD_STATIC ON)
  endif()

  set(AV_DEP_ZLIB_VERSION           "1.3.2")
  set(AV_DEP_ZLIB_URL               "https://zlib.net/zlib-${AV_DEP_ZLIB_VERSION}.tar.xz")
  set(AV_DEP_ZLIB_HASH              "SHA256=d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3")
  set(AV_DEP_ZLIB_EXTRA_CMAKE_FLAGS
    -DZLIB_BUILD_TESTING=OFF
    -DZLIB_BUILD_SHARED=${BUILD_SHARED_LIBS}
    -DZLIB_BUILD_STATIC=${AV_DEP_ZLIB_BUILD_STATIC}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_zlib_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of zlib...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(zlib URL ${AV_DEP_ZLIB_URL} URL_HASH "${AV_DEP_ZLIB_HASH}")

  # Build the dependency
  av_build_cmake_dependency(zlib
    EXTRA_CMAKE_ARGS ${AV_DEP_ZLIB_EXTRA_CMAKE_FLAGS}
  )

  # We must *patch* this :(
  # zlib's Config.cmake file expects that we build shared and static, but we
  # only build either one. Patch out the offending line
  # FIXME: FORK of zlib? Remove if fixed upstream!
  # We assume that the zlib file is at:
  # <CMAKE_INSTALL_PREFIX>/<CMAKE_INSTALL_LIBDIR>/cmake/zlib/zlibConfig.cmake
  if(NOT EXISTS "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/zlib/ZLIBConfig.cmake")
    message(FATAL_ERROR "PANIC! We must patch the ZLIBConfig.cmake file, but it is not at the expected location (${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/zlib/ZLIBConfig.cmake)!")
  endif()
  file(READ "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/zlib/ZLIBConfig.cmake" AV_DEP_zlib_CMAKE_CONFIG_FILE)
  set(AV_DEP_zlib_CMAKE_CONFIG_OFFENDING_STRING "set\\(_ZLIB_supported_components[ \t]*\"shared\"[ \t]*\"static\"\\)")
  if(AV_DEP_zlib_CMAKE_CONFIG_FILE MATCHES "${AV_DEP_zlib_CMAKE_CONFIG_OFFENDING_STRING}")
    # We patch and write back
    if(BUILD_SHARED_LIBS)
      string(REGEX REPLACE "${AV_DEP_zlib_CMAKE_CONFIG_OFFENDING_STRING}" "set(_ZLIB_supported_components \"shared\")" AV_DEP_zlib_CMAKE_CONFIG_FILE_PATCHED "${AV_DEP_zlib_CMAKE_CONFIG_FILE}")
    else()
      string(REGEX REPLACE "${AV_DEP_zlib_CMAKE_CONFIG_OFFENDING_STRING}" "set(_ZLIB_supported_components \"static\")" AV_DEP_zlib_CMAKE_CONFIG_FILE_PATCHED "${AV_DEP_zlib_CMAKE_CONFIG_FILE}")
      # We also need to create an alias target for ZLIB::ZLIB --> ZLIB::ZLIBSTATIC
      string(APPEND AV_DEP_zlib_CMAKE_CONFIG_FILE_PATCHED "\nif(NOT TARGET ZLIB::ZLIB)\n\tadd_library(ZLIB::ZLIB ALIAS ZLIB::ZLIBSTATIC)\nendif()\n")
    endif()

    # Write back the patched file
    file(WRITE "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/zlib/ZLIBConfig.cmake" "${AV_DEP_zlib_CMAKE_CONFIG_FILE_PATCHED}")
  endif()

endfunction()

# Invoke the function automatically
build_zlib()
