#
# AV_DependencyBuilderUtils.cmake
#
# This file contains helper functions for helping with building dependencies

# For warnings
include(AV_ColoredMessage)

# For parallel builds
include(ProcessorCount)

# # Global Index of the current dependency being built
# set(AV_DEP_CURRENT_MAKE_AVAIL_IDX 1)
# set(AV_DEP_CURRENT_BUILD_IDX 1)

# macro(_av_make_available_inc_index idx_string name should_not_count should_not_print)
#   if(NOT should_not_print)
#     av_colored_message(PLAIN G "${idx_string}" ! " Made " B "${name}" ! " available.")
#   endif()
#   if(NOT should_not_count)
#     math(EXPR AV_MAKE_AVAIL_NEW_IDX "${AV_DEP_CURRENT_MAKE_AVAIL_IDX} + 1")
#     set_property(GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX ${AV_MAKE_AVAIL_NEW_IDX})
#   endif()
# endmacro()

# macro(_av_build_inc_index idx_string name should_count should_print)
#   if(should_print)
#     av_colored_message(PLAIN G "${idx_string}" ! " Finished building " B "${name}" ! ".")
#   endif()
#   if(should_count)
#     math(EXPR AV_BUILD_NEW_IDX "${AV_DEP_CURRENT_BUILD_IDX} + 1")
#     set_property(GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX ${AV_BUILD_NEW_IDX})
#   endif()
# endmacro()

# # Makes a dependency available
# #
# # Call signature:
# # av_make_dependency_available(<DEP_NAME>
# #   <[GIT_REPO <REPO_URL> GIT_TAG <GIT_TAG>]
# #   |
# #   [URL <URL> URL_HASH <HASH>]>
# #   [NO_COUNT]
# #   [NO_PRINT]
# # )
# function(av_make_dependency_available AV_DEP_AVAIL_NAME)

#   # Parse arguments
#   cmake_parse_arguments(
#     AV_DEP_AVAIL
#     "NO_COUNT;NO_PRINT"                 # options
#     "GIT_REPO;GIT_TAG;URL;URL_HASH"     # one-value
#     ""                                  # multi-value
#     ${ARGN}
#   )

#   if(NOT AV_DEP_AVAIL_NO_PRINT)
#     # Build the current index string
#     set(AV_DEPS_ORDERED_COUNT 0)
#     foreach(AV_DEP IN LISTS AV_DEPS_ORDERED)
#       if(AV_DEP_${AV_DEP}_NO_BUILD)
#         continue()
#       endif()
#       math(EXPR AV_DEPS_ORDERED_COUNT "${AV_DEPS_ORDERED_COUNT}+1")
#     endforeach()
#     get_property(AV_DEP_CURRENT_MAKE_AVAIL_IDX GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX)
#     if(NOT DEFINED AV_DEP_CURRENT_MAKE_AVAIL_IDX)
#       set_property(GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX 1)
#       get_property(AV_DEP_CURRENT_MAKE_AVAIL_IDX GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX)
#     endif()
#     set(AV_DEP_AVAIL_IDX_STRING "[${AV_DEP_CURRENT_MAKE_AVAIL_IDX}/${AV_DEPS_ORDERED_COUNT}]")

#     av_colored_message(PLAIN G "${AV_DEP_AVAIL_IDX_STRING}" ! " Making " B "${AV_DEP_AVAIL_NAME}" ! " available...")
#   endif()

#   if(AV_DEP_AVAIL_GIT_REPO AND AV_DEP_AVAIL_URL)
#     message(FATAL_ERROR "Cannot specify GIT_REPO and URL in av_dep_make_available!")
#   endif()

#   if(NOT AV_DEP_AVAIL_GIT_REPO AND NOT AV_DEP_AVAIL_URL)
#     message(FATAL_ERROR "av_dep_make_available called without a source (specify GIT_REPO or URL)!")
#   endif()

#   macro(ensure_folders)
#     if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}")
#       file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}")
#     endif()
#     if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging")
#       file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging")
#     endif()
#     if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}")
#       file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}")
#     endif()
#   endmacro()

#   # Ensure folders are created
#   ensure_folders()

#   # If using GIT_REPO, Git must be available
#   if(AV_DEP_AVAIL_GIT_REPO AND NOT Git_FOUND)
#     find_package(Git QUIET)
#     if(NOT Git_FOUND)
#       message(FATAL_ERROR "Using av_dep_make_available with GIT_REPO requires Git to be installed!")
#     endif()
#   endif()

#   # If we are using Git, we clone directly into the ThirdParty folder
#   if(AV_DEP_AVAIL_GIT_REPO)
#     # Check if the Git repo is already cloned and clean
#     if(EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")
#       execute_process(COMMAND
#         ${GIT_EXECUTABLE}
#           diff
#           --exit-code
#         WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}"
#         RESULT_VARIABLE AV_DEP_INTEGRITY_RESULT
#       )
#       if(AV_DEP_INTEGRITY_RESULT EQUAL 1)
#         # Altered, remove the directory and start cloning again
#         file(REMOVE_RECURSE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")
#       else()
#         # All fine, return early
#         _av_make_available_inc_index("${AV_DEP_AVAIL_IDX_STRING}" "${AV_DEP_AVAIL_NAME}" ${AV_DEP_AVAIL_NO_COUNT} ${AV_DEP_AVAIL_NO_PRINT})
#         return()
#       endif()
#     endif()
#     if(AV_DEP_AVAIL_GIT_TAG)
#       set(AV_DEP_AVAIL_GIT_TAG_OPT --branch ${AV_DEP_AVAIL_GIT_TAG})
#     endif()
#     execute_process(COMMAND
#       ${GIT_EXECUTABLE}
#         clone
#         --depth 1                     # Shallow by default
#         --recursive                   # Clone all submodules by default
#         ${AV_DEP_AVAIL_GIT_REPO}
#         ${AV_DEP_AVAIL_GIT_TAG_OPT}   # Maybe we must clone a specific tag
#         "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}"
#       RESULT_VARIABLE AV_DEP_CLONE_RESULT
#       OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdOut.log"
#       ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdErr.log"
#     )
#     # Check Result
#     if(NOT AV_DEP_CLONE_RESULT EQUAL 0)
#       message(STATUS "${AV_DEP_CLONE_RESULT}")
#       message(FATAL_ERROR "Making available ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
#     endif()
#   elseif(AV_DEP_AVAIL_URL)
#     # If the directory exists, we assume that it was extracted correctly
#     # We will only rename it correctly after extracting finished
#     if(EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")
#       _av_make_available_inc_index("${AV_DEP_AVAIL_IDX_STRING}" "${AV_DEP_AVAIL_NAME}" ${AV_DEP_AVAIL_NO_COUNT} ${AV_DEP_AVAIL_NO_PRINT})
#       return()
#     endif()

#     # Download the file at URL
#     if(NOT AV_DEP_AVAIL_URL_HASH)
#       av_colored_message(PLAIN Y "Downloading archive from URL for ${AV_DEP_AVAIL_NAME} without specifying URL_HASH is unsafe!")
#     else()
#       set(AV_DEP_AVAIL_URL_HASH_ARG EXPECTED_HASH ${AV_DEP_AVAIL_URL_HASH})
#     endif()

#     # Get the filename from the URL
#     get_filename_component(AV_DEP_AVAIL_FILENAME "${AV_DEP_AVAIL_URL}" NAME)

#     # Downloads the file
#     file(DOWNLOAD
#       "${AV_DEP_AVAIL_URL}"
#       "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/${AV_DEP_AVAIL_FILENAME}"
#       ${AV_DEP_AVAIL_URL_HASH_ARG}
#       LOG
#         AV_DEP_DOWNLOAD_LOG
#     )

#     # Write the log to the file
#     file(WRITE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdOut.log" "${AV_DEP_DOWNLOAD_LOG}")
#     file(TOUCH "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdErr.log")

#     # Extract
#     file(ARCHIVE_EXTRACT INPUT "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/${AV_DEP_AVAIL_FILENAME}" DESTINATION "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}")

#     # This is derived from the CMake External_ProjectAdd
#     # code to extract the archives
#     # It essentially ensures that if the archive has a single
#     # sub-directory, it will be considered "the content" of
#     # the archive.
#     file(GLOB ARCHIVE_CONTENTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}/*")
#     list(REMOVE_ITEM ARCHIVE_CONTENTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}/.DS_Store")
#     list(LENGTH ARCHIVE_CONTENTS ARCHIVE_CONTENT_LENGTH)
#     if(ARCHIVE_CONTENT_LENGTH EQUAL 1)
#       # We need to move the inner folder to the upper one
#       get_filename_component(ARCHIVE_CONTENTS ${ARCHIVE_CONTENTS} ABSOLUTE)
#       # Rename back
#       file(RENAME "${ARCHIVE_CONTENTS}" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/__${AV_DEP_AVAIL_NAME}")
#       # Remove parent folder
#       file(REMOVE_RECURSE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}")
#     else()
#       # Just rename back
#       file(RENAME "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/__${AV_DEP_AVAIL_NAME}")
#     endif()

#     # Rename folder to indicate everything is done
#     file(RENAME "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/__${AV_DEP_AVAIL_NAME}" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")

#   endif()

#   _av_make_available_inc_index("${AV_DEP_AVAIL_IDX_STRING}" "${AV_DEP_AVAIL_NAME}" ${AV_DEP_AVAIL_NO_COUNT} ${AV_DEP_AVAIL_NO_PRINT})

# endfunction()

# # Builds a CMake dependency
# #
# # Must only be called after the dependency was made available with a call to
# # av_make_dependency_available().
# #
# # Call signature:
# # av_build_cmake_dependency(<DEP_NAME>
# #   [EXTRA_CMAKE_ARGS <CMAKE_ARGS>]
# #   [SPECIAL_SOURCE_DIR <DIR>]
# #   [NO_COUNT]
# #   [NO_PRINT]
# # )
# #
# # Note: EXTRA_CMAKE_ARGS has the ability to take a nested list (one layer),
# #       which might be useful for passing CMake lists as a -D variable on the
# #       CLI. The list elements must be seperated by "|".
# function(av_build_cmake_dependency AV_DEP_BUILD_NAME)

#   # Parse arguments
#   cmake_parse_arguments(
#     AV_DEP_BUILD
#     "NO_OPT"                                # options
#     "SPECIAL_SOURCE_DIR;PKG_CONFIG_PATH"    # one-value
#     "EXTRA_CMAKE_ARGS"                      # multi-value
#     ${ARGN}
#   )

#   # We need to re-build any args that contain "|", which will be interpreted
#   # as a list
#   function(av_parse_kv_list out_key out_list kv)
#     # Split key and value on '='
#     string(FIND "${kv}" "=" eq_pos)
#     if(eq_pos LESS 0)
#       message(FATAL_ERROR "Expected key=value, got: ${kv}")
#     endif()

#     string(SUBSTRING "${kv}" 0 ${eq_pos} key)
#     math(EXPR val_pos "${eq_pos}+1")
#     string(SUBSTRING "${kv}" ${val_pos} -1 val_raw)

#     # Convert custom separator '|' into CMake list separator ';'
#     string(REPLACE "|" ";" val_list "${val_raw}")

#     set(${out_key} "${key}" PARENT_SCOPE)
#     set(${out_list} "${val_list}" PARENT_SCOPE)
#   endfunction()

#   set(AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES)
#   set(AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX 0)
#   set(AV_DEP_BUILD_EXTRA_CMAKE_ARGS_NEW_ARGS)
#   foreach(AV_DEP_EXTRA_CMAKE_ARG IN LISTS AV_DEP_BUILD_EXTRA_CMAKE_ARGS)
#     string(FIND "${AV_DEP_EXTRA_CMAKE_ARG}" "|" _LIST_SYNTAX_IDX)
#     if(NOT _LIST_SYNTAX_IDX EQUAL -1)
#       av_parse_kv_list(_CMAKE_KEY _CMAKE_LIST "${AV_DEP_EXTRA_CMAKE_ARG}")
#       list(JOIN _CMAKE_LIST "\\\\\\;" _CMAKE_LIST_JOINED)
#       list(APPEND AV_DEP_BUILD_EXTRA_CMAKE_ARGS_NEW_ARGS "${_CMAKE_KEY}=${_CMAKE_LIST_JOINED}")
#       list(APPEND AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX})
#     endif()
#     math(EXPR AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX "${AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX}+1")
#   endforeach()
#   if(DEFINED AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES)
#     list(REMOVE_AT AV_DEP_BUILD_EXTRA_CMAKE_ARGS ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES})
#   endif()
#   foreach(AV_DEP_NEW_ARG IN LISTS AV_DEP_BUILD_EXTRA_CMAKE_ARGS_NEW_ARGS)
#     list(APPEND AV_DEP_BUILD_EXTRA_CMAKE_ARGS ${AV_DEP_NEW_ARG})
#   endforeach()

#   # Ensure that it was made available
#   if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}")
#     message(FATAL_ERROR "Attempting to build dependency ${AV_DEP_BUILD_NAME}, but it is not available at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}.")
#   endif()

#   # Build the current index string
#   set(AV_DEPS_ORDERED_COUNT 0)
#   foreach(AV_DEP IN LISTS AV_DEPS_ORDERED)
#     if(AV_DEP_${AV_DEP}_NO_BUILD)
#       continue()
#     endif()
#     math(EXPR AV_DEPS_ORDERED_COUNT "${AV_DEPS_ORDERED_COUNT}+1")
#   endforeach()
#   get_property(AV_DEP_CURRENT_BUILD_IDX GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX)
#   if(NOT DEFINED AV_DEP_CURRENT_BUILD_IDX)
#     set_property(GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX 1)
#     get_property(AV_DEP_CURRENT_BUILD_IDX GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX)
#   endif()
#   set(AV_DEP_BUILD_IDX_STRING "[${AV_DEP_CURRENT_BUILD_IDX}/${AV_DEPS_ORDERED_COUNT}]")

#   av_colored_message(PLAIN G "${AV_DEP_BUILD_IDX_STRING}" ! " Building " B "${AV_DEP_BUILD_NAME}" ! "...")

#   if(DEFINED AV_DEP_${AV_DEP_BUILD_NAME}_WAS_BUILT)
#     if(${AV_DEP_${AV_DEP_BUILD_NAME}_WAS_BUILT})
#       _av_build_inc_index("${AV_DEP_BUILD_IDX_STRING}" "${AV_DEP_BUILD_NAME}")
#       return()
#     endif()
#   endif()

#   # Build an escaped list of options for CMAKE_CXX_FLAGS
#   set(AV_DEP_BUILD_EXTRA_CFLAGS)
#   foreach(AV_DEP_BUILD_C_FLAG IN LISTS AV_OFA_FLAGS)
#     string(APPEND AV_DEP_BUILD_EXTRA_CFLAGS "${AV_DEP_BUILD_C_FLAG} ")
#   endforeach()

#   # Shared CMake dependency flags
#   set(AV_DEP_SHARED_CMAKE_FLAGS
#     # The C compiler should be the same as the one for the project
#     -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
#     # The C++ compiler should be the same as the one for the project
#     -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
#     # Pass build CMAKE_BUILD_TYPE
#     -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
#     # Pass Darwin architectures
#     -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
#     # Pass place to install
#     -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
#     # Pass the preferred prefix to look for sub-dependencies
#     -DCMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX}
#     -DCMAKE_FIND_USE_INSTALL_PREFIX=ON
#     # We prefer config mode, so it is more likely that our depdencies are used
#     -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON
#     # Shared Libraries
#     -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
#     # Might use ccache
#     -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
#     # Never build tests
#     -DBUILD_TESTING=OFF
#     # We can enable LTO support if we detected it works
#     -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=${AV_BUILD_WITH_LTO}
#     # Use the same build system
#     -G "${CMAKE_GENERATOR}"
#   )

#   # If NO_OPT is given, we disable OFA flags that otherwise would be included
#   if(NOT AV_DEP_BUILD_NO_OPT)
#     # Pass optimization flags
#     list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_C_FLAGS=${AV_DEP_BUILD_EXTRA_CFLAGS} -DCMAKE_CXX_FLAGS=${AV_DEP_BUILD_EXTRA_CFLAGS})
#   endif()

#   # We append ignore paths if AV_NO_SYSTEM_DEPS
#   if(AV_NO_SYSTEM_DEPS)
#   # Join the list into a single string WITHOUT quotes
#     list(JOIN AV_IGNORED_PREFIX_PATHS "\\;" AV_IGNORED_PREFIX_PATHS_JOINED)
#     list(APPEND AV_DEP_SHARED_CMAKE_FLAGS "-DCMAKE_IGNORE_PREFIX_PATH=${AV_IGNORED_PREFIX_PATHS_JOINED}")
#     list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_FIND_USE_PACKAGE_ROOT_PATH=OFF)
#     list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF)
#   endif()

#   # Install rpaths
#   if(AV_BUILD_ENABLE_RPTAHS)
#     # Join the list into a single string WITHOUT quotes
#     list(JOIN CMAKE_INSTALL_RPATH "\\;" AV_CMAKE_INSTALL_RPATHS_JOINED)
#     # Pass as a STRING cache entry (single argument)
#     list(APPEND AV_DEP_SHARED_CMAKE_FLAGS "-DCMAKE_INSTALL_RPATH=${AV_CMAKE_INSTALL_RPATHS_JOINED}")
#     list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_INSTALL_NAME_DIR=@rpath)
#   endif()

#   # Pass along any CMAKE_MSVC_RUNTIME_LIBRARY
#   if (WIN32 AND CMAKE_MSVC_RUNTIME_LIBRARY)
#       list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY})
#   endif ()

#   set(AV_DEP_BUILD_SOURCE_DIR "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}")
#   if(AV_DEP_BUILD_SPECIAL_SOURCE_DIR)
#     # Could be a relative folder, then treat it relative to the regular source
#     # dir
#     get_filename_component(AV_DEP_BUILD_SOURCE_DIR_ABSOLUTE "${AV_DEP_BUILD_SPECIAL_SOURCE_DIR}" ABSOLUTE BASE_DIR "${AV_DEP_BUILD_SOURCE_DIR}")
#     set(AV_DEP_BUILD_SOURCE_DIR "${AV_DEP_BUILD_SOURCE_DIR_ABSOLUTE}")
#   endif()

#   # For debugging purposes
#   if(AV_DEP_BUILD_VERBOSE)
#     execute_process(COMMAND ${CMAKE_COMMAND} -E echo
#       ${AV_DEP_SHARED_CMAKE_FLAGS}
#       ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS}  # Must be later in order to allow overwrites
#       -B "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
#       -S "${AV_DEP_BUILD_SOURCE_DIR}"
#     )
#   endif()

#   # Set the PKG_CONFIG_PATH, if required
#   if(AV_DEP_BUILD_PKG_CONFIG_PATH)
#       set(ENV{PKG_CONFIG_PATH} "${AV_DEP_BUILD_PKG_CONFIG_PATH}")
#   endif()
#   # Configure with CMake
#   execute_process(
#     ${AV_DEP_BUILD_PKG_CONFIG_PATH_ENV_COMMAND}
#     COMMAND
#     ${CMAKE_COMMAND}
#       -Wno-dev
#       -Wno-deprecated
#       --no-warn-unused-cli
#       -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF
#       -DCMAKE_VERBOSE_MAKEFILE=OFF
#       -DCMAKE_RULE_MESSAGES=OFF
#       ${AV_DEP_SHARED_CMAKE_FLAGS}
#       ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS}  # Must be later in order to allow overwrites
#       -B "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
#       -S "${AV_DEP_BUILD_SOURCE_DIR}"
#       RESULT_VARIABLE AV_DEP_BUILD_CONFIGURE_RESULT
#       OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeConfigureStdOut.log"
#       ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeConfigureStdErr.log"
#   )
#   if(NOT AV_DEP_BUILD_CONFIGURE_RESULT EQUAL 0)
#     message(FATAL_ERROR "The CMake Configure step for ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
#   endif()

#   # Determine maximum numbers Cores to use
#   ProcessorCount(AV_DEP_BUILD_AVAILABLE_CORES)

#   # Build with CMake
#   execute_process(COMMAND
#     ${CMAKE_COMMAND}
#       --build
#       "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
#       --parallel
#       ${AV_DEP_BUILD_AVAILABLE_CORES}
#       --config
#       ${CMAKE_BUILD_TYPE}
#       RESULT_VARIABLE AV_DEP_BUILD_BUILD_RESULT
#       OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeBuildStdOut.log"
#       ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeBuildStdErr.log"
#   )
#   if(NOT AV_DEP_BUILD_BUILD_RESULT EQUAL 0)
#     message(FATAL_ERROR "The CMake Build step for ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
#   endif()

#   # Determine if we want to strip the binaries (on Release an MinSizeRel)
#   if(CMAKE_BUILD_TYPE MATCHES "(Release|MinSizeRel)")
#     set(AV_DEP_BUILD_STRIP_ARG --strip)
#   endif()

#   # Install with CMake
#   execute_process(COMMAND
#     ${CMAKE_COMMAND}
#       --install
#       "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
#       --parallel
#       ${AV_DEP_BUILD_AVAILABLE_CORES}
#       --config
#       ${CMAKE_BUILD_TYPE}
#       ${AV_DEP_BUILD_STRIP_ARG}
#       RESULT_VARIABLE AV_DEP_BUILD_INSTALL_RESULT
#       OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeInstallStdOut.log"
#       ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeInstallStdErr.log"
#   )
#   if(NOT AV_DEP_BUILD_INSTALL_RESULT EQUAL 0)
#     message(FATAL_ERROR "The CMake Install step for ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
#   endif()

#   # We set a cache variable to indicate that this dependency was built. We will
#   # not built it again then.
#   set(AV_DEP_${AV_DEP_BUILD_NAME}_WAS_BUILT TRUE CACHE INTERNAL "The dependency ${AV_DEP_BUILD_NAME} has been built successfully")

#   _av_build_inc_index("${AV_DEP_BUILD_IDX_STRING}" "${AV_DEP_BUILD_NAME}")

# endfunction()

# Overlays a non-CMake project with a custom CMakeLists.txt file
#
# This is mainly useful if the project added a custom CMakeLists.txt file to
# ease building a library which has a non-standard build system.
#
# Call signature:
# av_overlay_with_cmakelists(<AV_DEP_OVERLAY_NAME>)
function(av_overlay_with_cmakelists AV_DEP_OVERLAY_NAME)

  # Parse arguments
  cmake_parse_arguments(
    AV_DEP_OVERLAY
    "FORCE_OVERWRITE"   # options
    ""                  # one-value
    ""                  # multi-value
    ${ARGN}
  )

  # If the folder for this dependency exists and a CMakeLists.txt
  # is present, do not overlay it (again).
  if(EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_OVERLAY_NAME}")

    # If a CMakeLists.txt file is present, do not overlay again
    if(EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_OVERLAY_NAME}/CMakeLists.txt" AND NOT AV_DEP_OVERLAY_FORCE_OVERWRITE)
      return()
    endif()

    # Try to find the overlay file
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/cmake/dependencies/overlays/Build_${AV_DEP_OVERLAY_NAME}_CMakeLists.txt")
      message(FATAL_ERROR "Unable to overlay dependency ${AV_DEP_OVERLAY_NAME}, because no matching CMakeLists.txt file exists!")
    endif()

    # Copy
    file(COPY_FILE "${CMAKE_SOURCE_DIR}/cmake/dependencies/overlays/Build_${AV_DEP_OVERLAY_NAME}_CMakeLists.txt" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_OVERLAY_NAME}/CMakeLists.txt" RESULT AV_DEP_OVERLAY_COPY_RESULT ONLY_IF_DIFFERENT)
    if(NOT AV_DEP_OVERLAY_COPY_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to overlay dependency ${AV_DEP_OVERLAY_NAME}, the copy operation for the CMakeLists.txt failed: ${AV_DEP_OVERLAY_COPY_RESULT}")
    endif()

    # We will also copy our generic CMakeConfig template
    file(COPY_FILE "${CMAKE_SOURCE_DIR}/cmake/templates/OverlayConfig.cmake.in" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_OVERLAY_NAME}/OverlayConfig.cmake.in" RESULT AV_DEP_OVERLAY_COPY_RESULT ONLY_IF_DIFFERENT)
    if(NOT AV_DEP_OVERLAY_COPY_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to overlay dependency ${AV_DEP_OVERLAY_NAME}, the copy operation for the OverlayConfig.cmake.in failed: ${AV_DEP_OVERLAY_COPY_RESULT}")
    endif()

  else()
    # Source folder not yet available
    message(FATAL_ERROR "Trying to overlay dependency ${AV_DEP_OVERLAY_NAME}, but it was not yet made available!")
  endif()

endfunction()

# Global Index of the current dependency being built
set(AV_DEP_CURRENT_MAKE_AVAIL_IDX 1)
set(AV_DEP_CURRENT_BUILD_IDX 1)

macro(_av_make_available_inc_index idx_string name should_not_count should_not_print)
  if(NOT ${should_not_print})
    av_colored_message(PLAIN G "${idx_string}" ! " Made " B "${name}" ! " available.")
  endif()
  if(NOT ${should_not_count})
    get_property(AV_DEP_CURRENT_MAKE_AVAIL_IDX GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX)
    if(NOT DEFINED AV_DEP_CURRENT_MAKE_AVAIL_IDX)
      set_property(GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX 1)
      get_property(AV_DEP_CURRENT_MAKE_AVAIL_IDX GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX)
    endif()
    math(EXPR AV_MAKE_AVAIL_NEW_IDX "${AV_DEP_CURRENT_MAKE_AVAIL_IDX} + 1")
    set_property(GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX ${AV_MAKE_AVAIL_NEW_IDX})
  endif()
endmacro()

macro(_av_build_inc_index idx_string name should_not_count should_not_print)
  if(NOT ${should_not_print})
    av_colored_message(PLAIN G "${idx_string}" ! " Finished building " B "${name}" ! ".")
  endif()
  if(NOT ${should_not_count})
    get_property(AV_DEP_CURRENT_BUILD_IDX GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX)
    if(NOT DEFINED AV_DEP_CURRENT_BUILD_IDX)
      set_property(GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX 1)
      get_property(AV_DEP_CURRENT_BUILD_IDX GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX)
    endif()
    math(EXPR AV_BUILD_NEW_IDX "${AV_DEP_CURRENT_BUILD_IDX} + 1")
    set_property(GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX ${AV_BUILD_NEW_IDX})
  endif()
endmacro()

# Makes a dependency available
#
# Call signature:
# av_make_dependency_available(<DEP_NAME>
#   <[GIT_REPO <REPO_URL> GIT_TAG <GIT_TAG>]
#   |
#   [URL <URL> URL_HASH <HASH>]>
#   [NO_COUNT]
#   [NO_PRINT]
# )
function(av_make_dependency_available AV_DEP_AVAIL_NAME)

  # Parse arguments
  cmake_parse_arguments(
    AV_DEP_AVAIL
    "NO_COUNT;NO_PRINT;NO_GIT_CHECK"    # options
    "GIT_REPO;GIT_TAG;URL;URL_HASH"     # one-value
    ""                                  # multi-value
    ${ARGN}
  )

  if(NOT AV_DEP_AVAIL_NO_PRINT)
    # Build the current index string
    set(AV_DEPS_ORDERED_COUNT 0)
    foreach(AV_DEP IN LISTS AV_DEPS_ORDERED)
      if(AV_DEP_${AV_DEP}_NO_BUILD)
        continue()
      endif()
      math(EXPR AV_DEPS_ORDERED_COUNT "${AV_DEPS_ORDERED_COUNT}+1")
    endforeach()
    get_property(AV_DEP_CURRENT_MAKE_AVAIL_IDX GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX)
    if(NOT DEFINED AV_DEP_CURRENT_MAKE_AVAIL_IDX)
      set_property(GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX 1)
      get_property(AV_DEP_CURRENT_MAKE_AVAIL_IDX GLOBAL PROPERTY AV_DEP_CURRENT_MAKE_AVAIL_IDX)
    endif()
    set(AV_DEP_AVAIL_IDX_STRING "[${AV_DEP_CURRENT_MAKE_AVAIL_IDX}/${AV_DEPS_ORDERED_COUNT}]")

    av_colored_message(PLAIN G "${AV_DEP_AVAIL_IDX_STRING}" ! " Making " B "${AV_DEP_AVAIL_NAME}" ! " available...")
  endif()

  if(AV_DEP_AVAIL_GIT_REPO AND AV_DEP_AVAIL_URL)
    message(FATAL_ERROR "Cannot specify GIT_REPO and URL in av_dep_make_available!")
  endif()

  if(NOT AV_DEP_AVAIL_GIT_REPO AND NOT AV_DEP_AVAIL_URL)
    message(FATAL_ERROR "av_dep_make_available called without a source (specify GIT_REPO or URL)!")
  endif()

  macro(ensure_folders)
    if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}")
      file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}")
    endif()
    if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging")
      file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging")
    endif()
    if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}")
      file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}")
    endif()
  endmacro()

  # Ensure folders are created
  ensure_folders()

  # If using GIT_REPO, Git must be available
  if(AV_DEP_AVAIL_GIT_REPO AND NOT Git_FOUND)
    find_package(Git QUIET)
    if(NOT Git_FOUND)
      message(FATAL_ERROR "Using av_dep_make_available with GIT_REPO requires Git to be installed!")
    endif()
  endif()

  # If we are using Git, we clone directly into the ThirdParty folder
  if(AV_DEP_AVAIL_GIT_REPO)
    # Check if the Git repo is already cloned and clean
    if(EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")
      execute_process(COMMAND
        ${GIT_EXECUTABLE}
          diff
          --exit-code
        OUTPUT_QUIET
        ERROR_QUIET
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}"
        RESULT_VARIABLE AV_DEP_INTEGRITY_RESULT
      )
      if(AV_DEP_INTEGRITY_RESULT EQUAL 1 AND NOT AV_DEP_AVAIL_NO_GIT_CHECK)
        # Altered, remove the directory and start cloning again
        file(REMOVE_RECURSE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")
      else()
        # All fine, return early
        _av_make_available_inc_index("${AV_DEP_AVAIL_IDX_STRING}" "${AV_DEP_AVAIL_NAME}" ${AV_DEP_AVAIL_NO_COUNT} ${AV_DEP_AVAIL_NO_PRINT})
        return()
      endif()
    endif()
    if(AV_DEP_AVAIL_GIT_TAG)
      set(AV_DEP_AVAIL_GIT_TAG_OPT --branch ${AV_DEP_AVAIL_GIT_TAG})
    endif()
    execute_process(COMMAND
      ${GIT_EXECUTABLE}
        clone
        --depth 1                     # Shallow by default
        --recursive                   # Clone all submodules by default
        ${AV_DEP_AVAIL_GIT_REPO}
        ${AV_DEP_AVAIL_GIT_TAG_OPT}   # Maybe we must clone a specific tag
        "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}"
      RESULT_VARIABLE AV_DEP_CLONE_RESULT
      OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdOut.log"
      ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdErr.log"
    )
    # Check Result
    if(NOT AV_DEP_CLONE_RESULT EQUAL 0)
      message(STATUS "${AV_DEP_CLONE_RESULT}")
      message(FATAL_ERROR "Making available ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
    endif()
  elseif(AV_DEP_AVAIL_URL)
    # If the directory exists, we assume that it was extracted correctly
    # We will only rename it correctly after extracting finished
    if(EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")
      _av_make_available_inc_index("${AV_DEP_AVAIL_IDX_STRING}" "${AV_DEP_AVAIL_NAME}" ${AV_DEP_AVAIL_NO_COUNT} ${AV_DEP_AVAIL_NO_PRINT})
      return()
    endif()

    # Download the file at URL
    if(NOT AV_DEP_AVAIL_URL_HASH)
      av_colored_message(PLAIN Y "Downloading archive from URL for ${AV_DEP_AVAIL_NAME} without specifying URL_HASH is unsafe!")
    else()
      set(AV_DEP_AVAIL_URL_HASH_ARG EXPECTED_HASH ${AV_DEP_AVAIL_URL_HASH})
    endif()

    # Get the filename from the URL
    get_filename_component(AV_DEP_AVAIL_FILENAME "${AV_DEP_AVAIL_URL}" NAME)

    # Downloads the file
    file(DOWNLOAD
      "${AV_DEP_AVAIL_URL}"
      "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/${AV_DEP_AVAIL_FILENAME}"
      ${AV_DEP_AVAIL_URL_HASH_ARG}
      LOG
        AV_DEP_DOWNLOAD_LOG
    )

    # Write the log to the file
    file(WRITE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdOut.log" "${AV_DEP_DOWNLOAD_LOG}")
    file(TOUCH "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}/MakeAvailableStdErr.log")

    # Extract
    file(ARCHIVE_EXTRACT INPUT "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/${AV_DEP_AVAIL_FILENAME}" DESTINATION "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}")

    # This is derived from the CMake External_ProjectAdd
    # code to extract the archives
    # It essentially ensures that if the archive has a single
    # sub-directory, it will be considered "the content" of
    # the archive.
    file(GLOB ARCHIVE_CONTENTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}/*")
    list(REMOVE_ITEM ARCHIVE_CONTENTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}/.DS_Store")
    list(LENGTH ARCHIVE_CONTENTS ARCHIVE_CONTENT_LENGTH)
    if(ARCHIVE_CONTENT_LENGTH EQUAL 1)
      # We need to move the inner folder to the upper one
      get_filename_component(ARCHIVE_CONTENTS ${ARCHIVE_CONTENTS} ABSOLUTE)
      # Rename back
      file(RENAME "${ARCHIVE_CONTENTS}" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/__${AV_DEP_AVAIL_NAME}")
      # Remove parent folder
      file(REMOVE_RECURSE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}")
    else()
      # Just rename back
      file(RENAME "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Staging/__${AV_DEP_AVAIL_NAME}" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/__${AV_DEP_AVAIL_NAME}")
    endif()

    # Rename folder to indicate everything is done
    file(RENAME "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/__${AV_DEP_AVAIL_NAME}" "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_AVAIL_NAME}")

  endif()

  _av_make_available_inc_index("${AV_DEP_AVAIL_IDX_STRING}" "${AV_DEP_AVAIL_NAME}" ${AV_DEP_AVAIL_NO_COUNT} ${AV_DEP_AVAIL_NO_PRINT})

endfunction()

# Builds a CMake dependency
#
# Must only be called after the dependency was made available with a call to
# av_make_dependency_available().
#
# Call signature:
# av_build_cmake_dependency(<DEP_NAME>
#   [EXTRA_CMAKE_ARGS <CMAKE_ARGS>]
#   [SPECIAL_SOURCE_DIR <DIR>]
#   [NO_COUNT]
#   [NO_PRINT]
# )
#
# Note: EXTRA_CMAKE_ARGS has the ability to take a nested list (one layer),
#       which might be useful for passing CMake lists as a -D variable on the
#       CLI. The list elements must be seperated by "|".
function(av_build_cmake_dependency AV_DEP_BUILD_NAME)

  # Parse arguments
  cmake_parse_arguments(
    AV_DEP_BUILD
    "NO_OPT;NO_COUNT;NO_PRINT"               # options
    "SPECIAL_SOURCE_DIR;PKG_CONFIG_PATH"     # one-value
    "EXTRA_CMAKE_ARGS"                       # multi-value
    ${ARGN}
  )

  # We need to re-build any args that contain "|", which will be interpreted
  # as a list
  function(av_parse_kv_list out_key out_list kv)
    # Split key and value on '='
    string(FIND "${kv}" "=" eq_pos)
    if(eq_pos LESS 0)
      message(FATAL_ERROR "Expected key=value, got: ${kv}")
    endif()

    string(SUBSTRING "${kv}" 0 ${eq_pos} key)
    math(EXPR val_pos "${eq_pos}+1")
    string(SUBSTRING "${kv}" ${val_pos} -1 val_raw)

    # Convert custom separator '|' into CMake list separator ';'
    string(REPLACE "|" ";" val_list "${val_raw}")

    set(${out_key} "${key}" PARENT_SCOPE)
    set(${out_list} "${val_list}" PARENT_SCOPE)
  endfunction()

  set(AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES)
  set(AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX 0)
  set(AV_DEP_BUILD_EXTRA_CMAKE_ARGS_NEW_ARGS)
  foreach(AV_DEP_EXTRA_CMAKE_ARG IN LISTS AV_DEP_BUILD_EXTRA_CMAKE_ARGS)
    string(FIND "${AV_DEP_EXTRA_CMAKE_ARG}" "|" _LIST_SYNTAX_IDX)
    if(NOT _LIST_SYNTAX_IDX EQUAL -1)
      av_parse_kv_list(_CMAKE_KEY _CMAKE_LIST "${AV_DEP_EXTRA_CMAKE_ARG}")
      list(JOIN _CMAKE_LIST "\\\\\\;" _CMAKE_LIST_JOINED)
      list(APPEND AV_DEP_BUILD_EXTRA_CMAKE_ARGS_NEW_ARGS "${_CMAKE_KEY}=${_CMAKE_LIST_JOINED}")
      list(APPEND AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX})
    endif()
    math(EXPR AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX "${AV_DEP_BUILD_EXTRA_CMAKE_ARGS_CURRENT_IDX}+1")
  endforeach()
  if(DEFINED AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES)
    list(REMOVE_AT AV_DEP_BUILD_EXTRA_CMAKE_ARGS ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS_INDICES})
  endif()
  foreach(AV_DEP_NEW_ARG IN LISTS AV_DEP_BUILD_EXTRA_CMAKE_ARGS_NEW_ARGS)
    list(APPEND AV_DEP_BUILD_EXTRA_CMAKE_ARGS ${AV_DEP_NEW_ARG})
  endforeach()

  # Ensure that it was made available
  if(NOT EXISTS "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}")
    message(FATAL_ERROR "Attempting to build dependency ${AV_DEP_BUILD_NAME}, but it is not available at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}.")
  endif()

  # Build the current index string
  set(AV_DEPS_ORDERED_COUNT 0)
  foreach(AV_DEP IN LISTS AV_DEPS_ORDERED)
    if(AV_DEP_${AV_DEP}_NO_BUILD)
      continue()
    endif()
    math(EXPR AV_DEPS_ORDERED_COUNT "${AV_DEPS_ORDERED_COUNT}+1")
  endforeach()
  get_property(AV_DEP_CURRENT_BUILD_IDX GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX)
  if(NOT DEFINED AV_DEP_CURRENT_BUILD_IDX)
    set_property(GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX 1)
    get_property(AV_DEP_CURRENT_BUILD_IDX GLOBAL PROPERTY AV_DEP_CURRENT_BUILD_IDX)
  endif()
  set(AV_DEP_BUILD_IDX_STRING "[${AV_DEP_CURRENT_BUILD_IDX}/${AV_DEPS_ORDERED_COUNT}]")

  if(NOT AV_DEP_BUILD_NO_PRINT)
    av_colored_message(PLAIN G "${AV_DEP_BUILD_IDX_STRING}" ! " Building " B "${AV_DEP_BUILD_NAME}" ! "...")
  endif()

  if(DEFINED AV_DEP_${AV_DEP_BUILD_NAME}_WAS_BUILT)
    if(${AV_DEP_${AV_DEP_BUILD_NAME}_WAS_BUILT})
      _av_build_inc_index("${AV_DEP_BUILD_IDX_STRING}" "${AV_DEP_BUILD_NAME}" ${AV_DEP_BUILD_NO_COUNT} ${AV_DEP_BUILD_NO_PRINT})
      return()
    endif()
  endif()

  # Build an escaped list of options for CMAKE_CXX_FLAGS
  set(AV_DEP_BUILD_EXTRA_CFLAGS)
  foreach(AV_DEP_BUILD_C_FLAG IN LISTS AV_OFA_FLAGS)
    string(APPEND AV_DEP_BUILD_EXTRA_CFLAGS "${AV_DEP_BUILD_C_FLAG} ")
  endforeach()

  # Shared CMake dependency flags
  set(AV_DEP_SHARED_CMAKE_FLAGS
    # The C compiler should be the same as the one for the project
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    # The C++ compiler should be the same as the one for the project
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    # Pass build CMAKE_BUILD_TYPE
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    # Pass Darwin architectures
    -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
    # Pass place to install
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    # Pass the preferred prefix to look for sub-dependencies
    -DCMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX}
    -DCMAKE_FIND_USE_INSTALL_PREFIX=ON
    # We prefer config mode, so it is more likely that our depdencies are used
    -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON
    # Shared Libraries
    -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
    # Might use ccache
    -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
    # Never build tests
    -DBUILD_TESTING=OFF
    # We can enable LTO support if we detected it works
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=${AV_BUILD_WITH_LTO}
    # Use the same build system
    -G "${CMAKE_GENERATOR}"
  )

  # If NO_OPT is given, we disable OFA flags that otherwise would be included
  if(NOT AV_DEP_BUILD_NO_OPT)
    # Pass optimization flags
    list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_C_FLAGS=${AV_DEP_BUILD_EXTRA_CFLAGS} -DCMAKE_CXX_FLAGS=${AV_DEP_BUILD_EXTRA_CFLAGS})
  endif()

  # We append ignore paths if AV_NO_SYSTEM_DEPS
  if(AV_NO_SYSTEM_DEPS)
  # Join the list into a single string WITHOUT quotes
    list(JOIN AV_IGNORED_PREFIX_PATHS "\\;" AV_IGNORED_PREFIX_PATHS_JOINED)
    list(APPEND AV_DEP_SHARED_CMAKE_FLAGS "-DCMAKE_IGNORE_PREFIX_PATH=${AV_IGNORED_PREFIX_PATHS_JOINED}")
    list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_FIND_USE_PACKAGE_ROOT_PATH=OFF)
    list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF)
  endif()

  # Install rpaths
  if(AV_BUILD_ENABLE_RPTAHS)
    # Join the list into a single string WITHOUT quotes
    list(JOIN CMAKE_INSTALL_RPATH "\\;" AV_CMAKE_INSTALL_RPATHS_JOINED)
    # Pass as a STRING cache entry (single argument)
    list(APPEND AV_DEP_SHARED_CMAKE_FLAGS "-DCMAKE_INSTALL_RPATH=${AV_CMAKE_INSTALL_RPATHS_JOINED}")
    list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_INSTALL_NAME_DIR=@rpath)
  endif()

  # Pass along any CMAKE_MSVC_RUNTIME_LIBRARY
  if (WIN32 AND CMAKE_MSVC_RUNTIME_LIBRARY)
      list(APPEND AV_DEP_SHARED_CMAKE_FLAGS -DCMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY})
  endif ()

  set(AV_DEP_BUILD_SOURCE_DIR "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}")
  if(AV_DEP_BUILD_SPECIAL_SOURCE_DIR)
    # Could be a relative folder, then treat it relative to the regular source
    # dir
    get_filename_component(AV_DEP_BUILD_SOURCE_DIR_ABSOLUTE "${AV_DEP_BUILD_SPECIAL_SOURCE_DIR}" ABSOLUTE BASE_DIR "${AV_DEP_BUILD_SOURCE_DIR}")
    set(AV_DEP_BUILD_SOURCE_DIR "${AV_DEP_BUILD_SOURCE_DIR_ABSOLUTE}")
  endif()

  # For debugging purposes
  if(AV_DEP_BUILD_VERBOSE)
    execute_process(COMMAND ${CMAKE_COMMAND} -E echo
      ${AV_DEP_SHARED_CMAKE_FLAGS}
      ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS}  # Must be later in order to allow overwrites
      -B "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
      -S "${AV_DEP_BUILD_SOURCE_DIR}"
    )
  endif()

  # Set the PKG_CONFIG_PATH, if required
  if(AV_DEP_BUILD_PKG_CONFIG_PATH)
      set(ENV{PKG_CONFIG_PATH} "${AV_DEP_BUILD_PKG_CONFIG_PATH}")
  endif()
  # Configure with CMake
  execute_process(
    ${AV_DEP_BUILD_PKG_CONFIG_PATH_ENV_COMMAND}
    COMMAND
    ${CMAKE_COMMAND}
      -Wno-dev
      -Wno-deprecated
      --no-warn-unused-cli
      -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF
      -DCMAKE_VERBOSE_MAKEFILE=OFF
      -DCMAKE_RULE_MESSAGES=OFF
      ${AV_DEP_SHARED_CMAKE_FLAGS}
      ${AV_DEP_BUILD_EXTRA_CMAKE_ARGS}  # Must be later in order to allow overwrites
      -B "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
      -S "${AV_DEP_BUILD_SOURCE_DIR}"
      RESULT_VARIABLE AV_DEP_BUILD_CONFIGURE_RESULT
      OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeConfigureStdOut.log"
      ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeConfigureStdErr.log"
  )
  if(NOT AV_DEP_BUILD_CONFIGURE_RESULT EQUAL 0)
    message(FATAL_ERROR "The CMake Configure step for ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
  endif()

  # Determine maximum numbers Cores to use
  ProcessorCount(AV_DEP_BUILD_AVAILABLE_CORES)

  # Build with CMake
  execute_process(COMMAND
    ${CMAKE_COMMAND}
      --build
      "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
      --parallel
      ${AV_DEP_BUILD_AVAILABLE_CORES}
      --config
      ${CMAKE_BUILD_TYPE}
      RESULT_VARIABLE AV_DEP_BUILD_BUILD_RESULT
      OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeBuildStdOut.log"
      ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeBuildStdErr.log"
  )
  if(NOT AV_DEP_BUILD_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "The CMake Build step for ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
  endif()

  # Determine if we want to strip the binaries (on Release an MinSizeRel)
  if(CMAKE_BUILD_TYPE MATCHES "(Release|MinSizeRel)")
    set(AV_DEP_BUILD_STRIP_ARG --strip)
  endif()

  # Install with CMake
  execute_process(COMMAND
    ${CMAKE_COMMAND}
      --install
      "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/${AV_DEP_BUILD_NAME}/__av_build"
      --parallel
      ${AV_DEP_BUILD_AVAILABLE_CORES}
      --config
      ${CMAKE_BUILD_TYPE}
      ${AV_DEP_BUILD_STRIP_ARG}
      RESULT_VARIABLE AV_DEP_BUILD_INSTALL_RESULT
      OUTPUT_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeInstallStdOut.log"
      ERROR_FILE "${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_BUILD_NAME}/CMakeInstallStdErr.log"
  )
  if(NOT AV_DEP_BUILD_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "The CMake Install step for ${AV_DEP_AVAIL_NAME} failed. Check the logs at ${CMAKE_BINARY_DIR}/ThirdParty/${AV_TARGET_TRIPLE}/Logs/${AV_DEP_AVAIL_NAME}.")
  endif()

  # We set a cache variable to indicate that this dependency was built. We will
  # not built it again then.
  set(AV_DEP_${AV_DEP_BUILD_NAME}_WAS_BUILT TRUE CACHE INTERNAL "The dependency ${AV_DEP_BUILD_NAME} has been built successfully")

  _av_build_inc_index("${AV_DEP_BUILD_IDX_STRING}" "${AV_DEP_BUILD_NAME}" ${AV_DEP_BUILD_NO_COUNT} ${AV_DEP_BUILD_NO_PRINT})

endfunction()
