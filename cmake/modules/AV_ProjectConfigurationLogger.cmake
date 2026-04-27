#
# AV_ProjectConfigurationLogger.cmake
#
# This file logs the current project configuration

# For printing colored messages
include(AV_ColoredMessage)

set(AV_BUILD_SETTINGS_LIST
  AV_BUILD_DEPENDENCIES
  AV_NO_SYSTEM_DEPS
  AV_BUILD_UNITTEST
  AV_BUILD_DOCS
  AV_BUILD_ENABLE_RPTAHS
  AV_BUILD_MESHROOM_PLUGIN
  AV_BUILD_SWIG_BINDING
  AV_BUILD_ASAN
  AV_BUILD_UBSAN
  AV_BUILD_COVERAGE
  AV_BUILD_WITH_LTO
)

set(AV_DEPENDENCY_SETTINGS
  AV_USE_OPENMP
  AV_USE_CCTAG
  AV_USE_APRILTAG
  AV_USE_ALEMBIC
  AV_USE_ONNX
  AV_USE_OPENCV
  AV_USE_USD
  AV_USE_CERES_ACCEL_SPARSE
  AV_USE_CUDA
  AV_USE_POPSIFT
  AV_USE_UNCERTAINTYTE
  AV_USE_ONNX_CUDA
  AV_USE_OPENCV_CONTRIB
  AV_USE_OPENCV_SIFT
  AV_USE_MOSEK
)

set(AV_PROJECT_COMPONENT_SETTINGS
  AV_BUILD_SFM
  AV_BUILD_SOFTWARE
  AV_BUILD_MVS
  AV_BUILD_HDR
  AV_BUILD_SEGMENTATION
  AV_BUILD_PHOTOMETRICSTEREO
  AV_BUILD_LIDAR
)

set(AV_PLATFORM_SPECIFIC_SETTINGS
  AV_BUILD_FRAMEWORKS
)

function(av_print_option_group GROUP_NAME OPTION_LIST)
  set(enabled "")
  set(disabled "")

  foreach(opt IN LISTS ${OPTION_LIST})
    if(${opt})
      list(APPEND enabled ${opt})
    else()
      list(APPEND disabled ${opt})
    endif()
  endforeach()

  av_colored_message(PLAIN W "===" B " ${GROUP_NAME} " W "===")
  av_colored_message(PLAIN "")

  if(enabled)
    foreach(opt IN LISTS enabled)
      av_colored_message(PLAIN G "  ☑" ! " ${opt}")
    endforeach()
    av_colored_message(PLAIN "")
  endif()

  if(disabled)
    foreach(opt IN LISTS disabled)
      set(reason_var "${opt}_DISABLED_REASON")

      if(DEFINED ${reason_var})
        set(reason "${${reason_var}}")
      else()
        set(reason "manually disabled by the user")
      endif()

      string(LENGTH "${opt}" opt_len)
      math(EXPR pad "30 - ${opt_len}")
      if(pad LESS 1)
        set(pad 1)
      endif()
      string(REPEAT " " ${pad} spacing)

      av_colored_message(PLAIN R "  ☒" ! " ${opt}${spacing}" W "(${reason})")
    endforeach()
    av_colored_message(PLAIN "")
  endif()
endfunction()

av_colored_message(PLAIN Y "======= Project Configuration Summary =======")
av_colored_message(PLAIN "")
av_print_option_group("Build Settings" AV_BUILD_SETTINGS_LIST)
av_print_option_group("Dependencies" AV_DEPENDENCY_SETTINGS)
av_print_option_group("Project Components" AV_PROJECT_COMPONENT_SETTINGS)
av_print_option_group("Platform Specific" AV_PLATFORM_SPECIFIC_SETTINGS)
av_colored_message(PLAIN W "===" B " CMake Configuration " W "===")
av_colored_message(PLAIN "")
av_colored_message(PLAIN B "  ☐ " ! "Build Type:            ${CMAKE_BUILD_TYPE}")
av_colored_message(PLAIN B "  ☐ " ! "Library Type:          ${AV_LIBRARY_TYPE}")
av_colored_message(PLAIN B "  ☐ " ! "Install Prefix:        ${CMAKE_INSTALL_PREFIX}")
av_colored_message(PLAIN B "  ☐ " ! "C++ Compiler:          ${CMAKE_CXX_COMPILER_ID}")
av_colored_message(PLAIN B "  ☐ " ! "C++ Linker:            ${CMAKE_CXX_COMPILER_LINKER_ID}")
av_colored_message(PLAIN B "  ☐ " ! "Optimization Flags:    ${AV_OFA_FLAGS}")
av_colored_message(PLAIN "")
