#
# AV_CMakeSetup.cmake
#
# This file serves the purpose of setting up relevant basic configuration for
# CMake (especially paths) and includes some useful helpers
#

# ===============================================
# Path setup
# ===============================================
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/ofa)


# ===============================================
# Integrity checks
# ===============================================
include(AV_IntegrityChecks)
include(AV_ConditionalOption)


# ===============================================
# Utility Includes
# ===============================================
include(GNUInstallDirs)


# ===============================================
# Sane default values
# ===============================================
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # Create compile_commands.json by default

# rpaths for Unix systems
# Assumes a standard Unix installation (with bin, lib[64], share, etc.)
# Adds some extra Apple standard stuff which would make it possible to use
# it in an Apple bundle style
if(APPLE)
  set(CMAKE_INSTALL_RPATH
    @executable_path/../${CMAKE_INSTALL_LIBDIR}
    @executable_path/../Libraries
    @executable_path/../Frameworks
    @loader_path/../${CMAKE_INSTALL_LIBDIR}
    @loader_path/../Libraries
    @loader_path/../Frameworks
  )
elseif(UNIX)
  set(CMAKE_INSTALL_RPATH
    $ORIGIN/
    $ORIGIN/../${CMAKE_INSTALL_LIBDIR}
  )
endif()

# Build Type
# If not set, default to Release builds
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()

# Library Type
# Default to shared Libraries
set(AV_LIBRARY_TYPE "Static")
if(NOT DEFINED BUILD_SHARED_LIBS)
  set(BUILD_SHARED_LIBS ON)
  set(AV_LIBRARY_TYPE "Shared")
endif()

# Initialize CMAKE_OSX_ARCHITECTURES, if not specified on the command line.
if(APPLE AND NOT CMAKE_OSX_ARCHITECTURES)
  set(CMAKE_OSX_ARCHITECTURES ${CMAKE_HOST_SYSTEM_PROCESSOR} CACHE STRING "Apple architecture" FORCE)
endif()

# Check if we are cross-compiling
if(CMAKE_CROSSCOMPILING OR NOT CMAKE_OSX_ARCHITECTURES STREQUAL CMAKE_HOST_SYSTEM_PROCESSOR)
  set(AV_IS_CROSSCOMPILING TRUE)
endif()

# System paths which should be ignored if AV_NO_SYSTEM_DEPS is enabled
if(APPLE)
  set(AV_IGNORED_PREFIX_PATHS
    # Intel Mac Homebrew
    "/usr/local"
    "/usr/local/Cellar"
    "/usr/local/Frameworks"
    "/usr/local/lib"
    "/usr/local/Library"
    "/usr/local/opt"
    # Apple Silicon Homebrew
    "/opt/homebrew"
    "/opt/homebrew/Cellar"
    "/opt/homebrew/Frameworks"
    "/opt/homebrew/lib"
    "/opt/homebrew/Library"
    "/opt/homebrew/opt"
    # MacPorts
    "/opt/local"
    # Nix
    "/nix/store"
  )
elseif(LINUX)

elseif(WIN32)

endif()

# Perform CPU optimization detection
include(OptimizeForArchitecture)
OptimizeForArchitecture()

# Add install prefix to search path
set(CMAKE_FIND_USE_INSTALL_PREFIX ON)
list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})

# A variable always evaluating to OFF
set(AV_NEVER OFF)
