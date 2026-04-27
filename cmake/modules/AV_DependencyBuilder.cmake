#
# AV_DependencyBuilder.cmake
#
# Orchestrates the build of embedded dependencies

# (1) Iterate the generated list from av_finalize_dependencies
#     For each dependency:
#     (2) Check that a Build_<DEP_NAME>.cmake file exists
#     (3) Include it

# We need the Builder Utils
include(AV_DependencyBuilderUtils)

# We might print colored messages
include(AV_ColoredMessage)

foreach(AV_DEP IN LISTS AV_DEPS_ORDERED)

  # Skip the dependency if it should not be built
  # because it is NEVER_BUILD
  if(AV_DEP_${AV_DEP}_NEVER_BUILD)
    continue()
  endif()

  # Skip the dependency if not build file is available
  set(AV_DEP_BUILD_FILE "${CMAKE_SOURCE_DIR}/cmake/dependencies/Build_${AV_DEP}.cmake")
  if(NOT EXISTS "${AV_DEP_BUILD_FILE}")
    av_colored_message(PLAIN Y "WARN: " ! "Build file for ${AV_DEP} was not found, skipping build...")
    continue()
  endif()

  # Include the build file
  include(${AV_DEP_BUILD_FILE})

endforeach()
