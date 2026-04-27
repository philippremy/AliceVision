#
# AV_IntegrityChecks.cmake
#
# This file serves the purpose of checking some prerequisites before continuing
# the configuration process
#

# ===============================================
# No in-source builds
# ===============================================
if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
message(FATAL_ERROR
"In-source builds not allowed, create a build directory and try again.
This process created the file `CMakeCache.txt' and the directory `CMakeFiles'.
Please delete them."
)
endif()
