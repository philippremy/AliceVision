#
# AV_DependencyFinderUtils.cmake
#
# Utility functions for findind required dependencies

include(AV_ColoredMessage)

# Finds a dependency and sets some relevant variables to use the dependency
# correctly
#
# Call signature:
# av_find_dependency(<DEPENDENCY_NAME>
#   (TARGET <TARGET> | (STATIC_TARGET <STATIC_TARGET_NAME> SHARED_TARGET <SHARED_TARGET_NAME>))
#   [MIN_VERSION <MINIMUM_VERSION>]
#   [MAX_VERSION <MAXIMUM_VERSION>]
#   [ALLOW_MODULE]
# )
#
# Sets:
# AV_DEP_<NAME>_FOUND
# AV_DEP_<NAME>_ALL_LINK_TARGETS
# AV_DEP_<NAME>_VERSION
# AV_DEP_<NAME>_NOT_FOUND_REASON
#
# Internal sets:
# __AV_CONFIG_HAVE_<NAME>
#
# Appends:
# AV_DEP_ALL_FOUND
# AV_DEP_ALL_NOTFOUND
function(av_find_dependency AV_DEP_FIND_NAME)

  # Parse arguments
  cmake_parse_arguments(
    AV_DEP_FIND
    "ALLOW_MODULE;REQUIRED;NO_CONFIG;EXTRA_QUIET"                                         # options
    "MIN_VERSION;MAX_VERSION;MODULE_PATH"                                                 # one-value
    "COMPONENTS;OPTIONAL_COMPONENTS;TARGETS;STATIC_TARGETS;SHARED_TARGETS;REQUIRED_IF"    # multi-value
    ${ARGN}
  )

  if(AV_DEP_FIND_TARGETS AND (AV_DEP_FIND_STATIC_TARGETS OR AV_DEP_FIND_SHARED_TARGETS))
    message(FATAL_ERROR "Cannot specify a unified target and special targets for STATIC and SHARED!")
  endif()

  if(NOT AV_DEP_FIND_TARGETS AND (NOT AV_DEP_FIND_STATIC_TARGETS OR NOT AV_DEP_FIND_SHARED_TARGETS))
    message(FATAL_ERROR "Cannot specify no unified target and no special targets for STATIC and SHARED!")
  endif()

  if(AV_DEP_FIND_REQUIRED AND AV_DEP_FIND_REQUIRED_IF)
    message(FATAL_ERROR "Cannot handle unconditional REQUIRED and conditional REQUIRED_IF clause!")
  endif()

  # Parse REQUIRED_IF clause
  if(AV_DEP_FIND_REQUIRED_IF)
    if(${AV_DEP_FIND_REQUIRED_IF})
      set(AV_DEP_FIND_REQUIRED TRUE)
    else()
      set(AV_DEP_FIND_REQUIRED FALSE)
    endif()
  endif()

  set(AV_DEP_FIND_ALLOW_MODULE_FLAG)
  if(NOT AV_DEP_FIND_ALLOW_MODULE)
    set(AV_DEP_FIND_ALLOW_MODULE_FLAG NO_MODULE)
  endif()

  # Maximum version will be manually checked after a module was found
  set(AV_DEP_FIND_VERSION_FLAG)
  if(AV_DEP_FIND_MIN_VERSION)
    set(AV_DEP_FIND_VERSION_FLAG ${AV_DEP_FIND_MIN_VERSION})
  endif()

  set(AV_DEP_FIND_COMPONENT_FLAG)
  if(AV_DEP_FIND_COMPONENTS)
    set(AV_DEP_FIND_COMPONENT_FLAG COMPONENTS ${AV_DEP_FIND_COMPONENTS})
  endif()

  set(AV_DEP_FIND_OPTIONAL_COMPONENT_FLAG)
  if(AV_DEP_FIND_OPTIONAL_COMPONENTS)
    set(AV_DEP_FIND_OPTIONAL_COMPONENT_FLAG OPTIONAL_COMPONENTS ${AV_DEP_FIND_OPTIONAL_COMPONENTS})
  endif()

  set(AV_DEP_FIND_CONFIG_FLAG)
  if(NOT AV_DEP_FIND_NO_CONFIG)
    set(AV_DEP_FIND_CONFIG_FLAG CONFIG)
  endif()

  # We must temporarily add a new module path
  if(AV_DEP_FIND_MODULE_PATH)
    list(APPEND CMAKE_MODULE_PATH ${AV_DEP_FIND_MODULE_PATH})
  endif()

  # If EXTRA_QUIET is enabled, the script might print stuff we don't want to
  # see. The solution is to temporarily set the global log level to a ERROR
  # and set it back after the find_package() call returns
  cmake_language(GET_MESSAGE_LOG_LEVEL AV_DEP_FIND_CURRENT_LOG_LEVEL)
  if(AV_DEP_FIND_EXTRA_QUIET)
    set(CMAKE_MESSAGE_LOG_LEVEL ERROR CACHE INTERNAL "Current log level" FORCE)
  endif()

  # Invoke find_package()
  find_package(${AV_DEP_FIND_NAME}
    ${AV_DEP_FIND_VERSION_FLAG}
    QUIET
    ${AV_DEP_FIND_COMPONENT_FLAG}
    ${AV_DEP_FIND_OPTIONAL_COMPONENT_FLAG}
    ${AV_DEP_FIND_CONFIG_FLAG}
    ${AV_DEP_FIND_ALLOW_MODULE_FLAG}
  )

  # Set back the logging level
  if(AV_DEP_FIND_EXTRA_QUIET)
    set(CMAKE_MESSAGE_LOG_LEVEL ERROR ${AV_DEP_FIND_CURRENT_LOG_LEVEL} CACHE INTERNAL "Current log level" FORCE)
  endif()

  # Remove the temporary module path
  if(AV_DEP_FIND_MODULE_PATH)
    list(REMOVE_ITEM CMAKE_MODULE_PATH ${AV_DEP_FIND_MODULE_PATH})
  endif()

  # Found/Not Found
  if(NOT ${AV_DEP_FIND_NAME}_FOUND)
    if(AV_DEP_FIND_REQUIRED)
      message(FATAL_ERROR "Required dependency ${AV_DEP_FIND_NAME} was not found at all!")
    else()
      set(AV_DEP_${AV_DEP_FIND_NAME}_FOUND FALSE PARENT_SCOPE)
      set(__AV_CONFIG_HAVE_${AV_DEP_FIND_NAME} 0 CACHE BOOL "AliceVision has ${AV_DEP_FIND_NAME} available" FORCE)
      set(AV_DEP_${AV_DEP_FIND_NAME}_NOT_FOUND_REASON "Not found at all" PARENT_SCOPE)
      list(APPEND AV_DEP_ALL_NOTFOUND ${AV_DEP_FIND_NAME})
      set(AV_DEP_ALL_NOTFOUND ${AV_DEP_ALL_NOTFOUND} PARENT_SCOPE)
      return()
    endif()
  endif()

  # Version checks
  if(${AV_DEP_FIND_NAME}_VERSION)
    if(AV_DEP_FIND_MAX_VERSION)
      if(${AV_DEP_FIND_NAME}_VERSION VERSION_GREATER ${AV_DEP_FIND_MAX_VERSION})
        if(AV_DEP_FIND_REQUIRED)
          message(FATAL_ERROR "Required dependency ${AV_DEP_FIND_NAME} was found but its version is higher than the allowed maximum version (${${AV_DEP_FIND_NAME}_VERSION} / ${AV_DEP_FIND_MAX_VERSION})!")
        else()
          set(AV_DEP_${AV_DEP_FIND_NAME}_FOUND FALSE PARENT_SCOPE)
          set(__AV_CONFIG_HAVE_${AV_DEP_FIND_NAME} 0 CACHE BOOL "AliceVision has ${AV_DEP_FIND_NAME} available" FORCE)
          set(AV_DEP_${AV_DEP_FIND_NAME}_NOT_FOUND_REASON "Found but exceeded maximum version (${${AV_DEP_FIND_NAME}_VERSION} / ${AV_DEP_FIND_MAX_VERSION})" PARENT_SCOPE)
          list(APPEND AV_DEP_ALL_NOTFOUND ${AV_DEP_FIND_NAME})
          set(AV_DEP_ALL_NOTFOUND ${AV_DEP_ALL_NOTFOUND} PARENT_SCOPE)
          return()
        endif()
      else()
        set(AV_DEP_${AV_DEP_FIND_NAME}_VERSION "${${AV_DEP_FIND_NAME}_VERSION}" PARENT_SCOPE)
      endif()
    else()
      set(AV_DEP_${AV_DEP_FIND_NAME}_VERSION "${${AV_DEP_FIND_NAME}_VERSION}" PARENT_SCOPE)
    endif()
  else()
    set(AV_DEP_${AV_DEP_FIND_NAME}_VERSION "N/A" PARENT_SCOPE)
  endif()

  # Check targets
  set(AV_DEP_${AV_DEP_FIND_NAME}_LINK_TARGET)
  if(AV_DEP_FIND_TARGETS)
    foreach(AV_DEP_FIND_TARGET IN LISTS AV_DEP_FIND_TARGETS)
      if(NOT TARGET ${AV_DEP_FIND_TARGET})
        if(AV_DEP_FIND_REQUIRED)
          message(FATAL_ERROR "Required dependency ${AV_DEP_FIND_NAME} was found but did not provide the expected unified target (${AV_DEP_FIND_TARGET})!")
        else()
          set(AV_DEP_${AV_DEP_FIND_NAME}_FOUND FALSE PARENT_SCOPE)
          set(__AV_CONFIG_HAVE_${AV_DEP_FIND_NAME} 0 CACHE BOOL "AliceVision has ${AV_DEP_FIND_NAME} available" FORCE)
          set(AV_DEP_${AV_DEP_FIND_NAME}_NOT_FOUND_REASON "Found but expected target did not exist (${AV_DEP_FIND_TARGET})" PARENT_SCOPE)
          list(APPEND AV_DEP_ALL_NOTFOUND ${AV_DEP_FIND_NAME})
          set(AV_DEP_ALL_NOTFOUND ${AV_DEP_ALL_NOTFOUND} PARENT_SCOPE)
          return()
        endif()
      else()
        list(APPEND AV_DEP_${AV_DEP_FIND_NAME}_LINK_TARGET ${AV_DEP_FIND_TARGET})
      endif()
    endforeach()
  else()
    if(BUILD_SHARED_LIBS)
      foreach(AV_DEP_FIND_SHARED_TARGET IN LISTS AV_DEP_FIND_SHARED_TARGETS)
        if(NOT TARGET ${AV_DEP_FIND_SHARED_TARGET})
          if(AV_DEP_FIND_REQUIRED)
            message(FATAL_ERROR "Required dependency ${AV_DEP_FIND_NAME} was found but did not provide the expected shared target (${AV_DEP_FIND_SHARED_TARGET})!")
          else()
            set(AV_DEP_${AV_DEP_FIND_NAME}_FOUND FALSE PARENT_SCOPE)
            set(AV_DEP_${AV_DEP_FIND_NAME}_NOT_FOUND_REASON "Found but expected shared target did not exist (${AV_DEP_FIND_SHARED_TARGET})" PARENT_SCOPE)
            list(APPEND AV_DEP_ALL_NOTFOUND ${AV_DEP_FIND_NAME})
            set(AV_DEP_ALL_NOTFOUND ${AV_DEP_ALL_NOTFOUND} PARENT_SCOPE)
            return()
          endif()
        else()
          list(APPEND AV_DEP_${AV_DEP_FIND_NAME}_LINK_TARGET ${AV_DEP_FIND_SHARED_TARGET})
        endif()
      endforeach()
    else()
      foreach(AV_DEP_FIND_STATIC_TARGET IN LISTS AV_DEP_FIND_STATIC_TARGETS)
        if(NOT TARGET ${AV_DEP_FIND_STATIC_TARGET})
          if(AV_DEP_FIND_REQUIRED)
            message(FATAL_ERROR "Required dependency ${AV_DEP_FIND_NAME} was found but did not provide the expected static target (${AV_DEP_FIND_STATIC_TARGET})!")
          else()
            set(AV_DEP_${AV_DEP_FIND_NAME}_FOUND FALSE PARENT_SCOPE)
            set(__AV_CONFIG_HAVE_${AV_DEP_FIND_NAME} 0 CACHE BOOL "AliceVision has ${AV_DEP_FIND_NAME} available" FORCE)
            set(AV_DEP_${AV_DEP_FIND_NAME}_NOT_FOUND_REASON "Found but expected static target did not exist (${AV_DEP_FIND_STATIC_TARGET})" PARENT_SCOPE)
            list(APPEND AV_DEP_ALL_NOTFOUND ${AV_DEP_FIND_NAME})
            set(AV_DEP_ALL_NOTFOUND ${AV_DEP_ALL_NOTFOUND} PARENT_SCOPE)
            return()
          endif()
        else()
          list(APPEND AV_DEP_${AV_DEP_FIND_NAME}_LINK_TARGET ${AV_DEP_FIND_STATIC_TARGET})
        endif()
      endforeach()
    endif()
  endif()

  # Finally set that it was found
  set(AV_DEP_${AV_DEP_FIND_NAME}_FOUND TRUE PARENT_SCOPE)

  # Finally set that it was found
  set(__AV_CONFIG_HAVE_${AV_DEP_FIND_NAME} 1 CACHE BOOL "AliceVision has ${AV_DEP_FIND_NAME} available" FORCE)

  # Set the target
  set(AV_DEP_${AV_DEP_FIND_NAME}_ALL_LINK_TARGETS ${AV_DEP_${AV_DEP_FIND_NAME}_LINK_TARGET} PARENT_SCOPE)

  # Add to found list
  list(APPEND AV_DEP_ALL_FOUND ${AV_DEP_FIND_NAME})
  set(AV_DEP_ALL_FOUND ${AV_DEP_ALL_FOUND} PARENT_SCOPE)

endfunction()
