#
# AV_CompilerDetection.cmake
#
# This file serves the purpose of detecting the compilation environment
# and the capabilities of the compiler
#

include(CheckCXXCompilerFlag)
include(CheckIPOSupported)

# ===============================================
# Compilation Environment Detection
#
# Sets the following variables:
#
# AV_COMPILER_GNU_COMPATIBLE    --> Has a GNU style compatible CLI
# AV_COMPILER_MSVC_COMPATIBLE   --> Has a MSVC style compatible CLI
# AV_COMPILER_IS_LLVM           --> Is an LLVM based compiler
# AV_COMPILER_IS_GNU            --> Is a GNU compiler
# AV_COMPILER_IS_MSVC           --> Is an MSVC compiler
#
# AV_COMPILER_SUPPORTS_ASAN     --> Supports AddressSanitizer
# AV_COMPILER_SUPPORTS_UBSAN    --> Supports UndefinedBehaviorSanitizer
#
# AV_COMPILER_SUPPORTS_LTO      --> Supports Link-Time-Optimization
# ===============================================

# Compiler family detection
if(CMAKE_CXX_COMPILER_ID MATCHES "(AppleClang|Clang|GNU)")
  set(AV_COMPILER_GNU_COMPATIBLE TRUE)
else()
  set(AV_COMPILER_GNU_COMPATIBLE FALSE)
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC" OR MSVC)
  set(AV_COMPILER_MSVC_COMPATIBLE TRUE)
else()
  set(AV_COMPILER_MSVC_COMPATIBLE FALSE)
endif()

# GNU/LLVM/MSVC detection
set(AV_COMPILER_IS_LLVM FALSE)
set(AV_COMPILER_IS_GNU  FALSE)
set(AV_COMPILER_IS_MSVC FALSE)
if(CMAKE_CXX_COMPILER_ID MATCHES "(LLVM|Clang|AppleClang)")
  set(AV_COMPILER_IS_LLVM TRUE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  set(AV_COMPILER_IS_GNU  TRUE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  set(AV_COMPILER_IS_MSVC TRUE)
endif()

# Sanitizers
if(AV_COMPILER_GNU_COMPATIBLE)

  # AddressSanitizer
  check_cxx_compiler_flag("-fsanitize=address" AV_GNULIKE_COMPILER_SUPPORTS_ASAN)
  if(AV_GNULIKE_COMPILER_SUPPORTS_ASAN)
    set(AV_COMPILER_SUPPORTS_ASAN TRUE)
  else()
    set(AV_COMPILER_SUPPORTS_ASAN FALSE)
  endif()

  # UndefinedBehaviorSanitizer
  check_cxx_compiler_flag("-fsanitize=undefined" AV_GNULIKE_COMPILER_SUPPORTS_UBSAN)
  if(AV_GNULIKE_COMPILER_SUPPORTS_UBSAN)
    set(AV_COMPILER_SUPPORTS_UBSAN TRUE)
  else()
    set(AV_COMPILER_SUPPORTS_UBSAN FALSE)
  endif()

elseif(AV_COMPILER_MSVC_COMPATIBLE)

  # AddressSanitizer
  check_cxx_compiler_flag("/fsanitize=address" AV_MSVCLIKE_COMPILER_SUPPORTS_ASAN)
  if(AV_MSVCLIKE_COMPILER_SUPPORTS_ASAN)
    set(AV_COMPILER_SUPPORTS_ASAN TRUE)
  else()
    set(AV_COMPILER_SUPPORTS_ASAN FALSE)
  endif()

  # UndefinedBehaviorSanitizer not supported on MSVC
  set(AV_COMPILER_SUPPORTS_UBSAN FALSE)

endif()

# LTO
if(NOT DEFINED AV_COMPILER_SUPPORTS_LTO)
  message(STATUS "Performing Test AV_COMPILER_SUPPORTS_LTO")
  check_ipo_supported(RESULT CHECK_AV_COMPILER_SUPPORTS_LTO LANGUAGES C CXX)
  if(CHECK_AV_COMPILER_SUPPORTS_LTO)
    set(AV_COMPILER_SUPPORTS_LTO TRUE CACHE INTERNAL "LTO/IPO is supported by the C++ Compiler" FORCE)
    message(STATUS "Performing Test AV_COMPILER_SUPPORTS_LTO - Success")
  else()
    set(AV_COMPILER_SUPPORTS_LTO FALSE CACHE INTERNAL "LTO/IPO is supported by the C++ Compiler" FORCE)
    message(STATUS "Performing Test AV_COMPILER_SUPPORTS_LTO - Failed")
  endif()
endif()
