# This module provides a function to find the ONNX Runtime library
#
# Usage:
#   find_package(ONNXRuntime REQUIRED)
#   target_link_libraries(mytarget PRIVATE ${ONNXRuntime_LIBRARIES})

# Set the search paths for the library and headers
find_library(ONNXRuntime_LIBRARY
  NAMES onnxruntime
  HINTS ${AV_ONNX_INSTALL_PREFIX}
  PATH_SUFFIXES lib lib64
)

find_path(ONNXRuntime_INCLUDE_DIR
  NAMES onnxruntime_cxx_api.h
  HINTS ${AV_ONNX_INSTALL_PREFIX}
  PATH_SUFFIXES include include/onnxruntime  include/onnxruntime/core/session
)

set(__AV_CONFIG_HAVE_ONNXRuntimeGPU 0 CACHE BOOL "AliceVision has ONNXRuntime with GPU support (CUDA) available" FORCE)
if(EXISTS ONNXRuntime_INCLUDE_DIR)
  if(EXISTS "${ONNXRuntime_INCLUDE_DIR}/core/cuda")
    set(__AV_CONFIG_HAVE_ONNXRuntimeGPU 1 CACHE BOOL "AliceVision has ONNXRuntime with GPU support (CUDA) available" FORCE)
  endif()
endif()

# Check that we found everything we need
if (ONNXRuntime_LIBRARY AND ONNXRuntime_INCLUDE_DIR)

  # Export the target for downstream use
  add_library(ONNXRuntime::ONNXRuntime INTERFACE IMPORTED)
  set_target_properties(ONNXRuntime::ONNXRuntime PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${ONNXRuntime_INCLUDE_DIR}"
    INTERFACE_LINK_LIBRARIES "${ONNXRuntime_LIBRARY}"
  )

  # Export variables for use in downstream projects
  set(ONNXRuntime_FOUND TRUE)
  set(ONNXRuntime_INCLUDE_DIRS "${ONNXRuntime_INCLUDE_DIR}")
  set(ONNXRuntime_LIBRARIES "${ONNXRuntime_LIBRARY}")
  mark_as_advanced(ONNXRuntime_INCLUDE_DIRS ONNXRuntime_LIBRARIES)

endif()
