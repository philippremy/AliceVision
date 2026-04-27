# This file is copied from https://gitlab.inf.unibe.ch/CGG-public/CoMISo/CoMISo
# which is licensed under the General Public License (GPL).
#
# Therefore, this file must be relicensed under GLP.
# See LICENSE_GPL.txt
#
# Once done this will (on success) define the following:
#       MOSEK::Mosek      - only the C interface
#       MOSEK::FusionCXX  - Fusion C++ library, must be compiled

# The enviroment variable AV_MOSEK_DIR can be used to initialize MOSEK_BASE

find_path (MOSEK_BASE
    NAMES tools/platform
    PATHS
    ${AV_MOSEK_DIR}
    DOC "Base path of your MOSEK installation")

file(GLOB MOSEK_PLATFORM_DIRS LIST_DIRECTORIES TRUE "${MOSEK_BASE}/tools/platform/*")
if(MOSEK_PLATFORM_DIRS)
  list(REMOVE_ITEM MOSEK_PLATFORM_DIRS "${MOSEK_BASE}/tools/platform/.DS_Store")
  list(GET MOSEK_PLATFORM_DIRS 0 MOSEK_PLATFORM_DIR)
endif()

set (MOSEK_PLATFORM_PATH "${MOSEK_PLATFORM_DIR}")

find_path (MOSEK_INCLUDE_DIR
           NAMES mosek.h
           PATHS "${MOSEK_PLATFORM_PATH}/h"
          )

find_path (MOSEK_LIBRARY_DIR
           NAMES libmosek64.dylib
                 libmosek64.so
                 mosek64_9_2.dll
           PATHS "${MOSEK_PLATFORM_PATH}/bin")

find_library (MOSEK_LIBRARY
              NAMES mosek64
              PATHS "${MOSEK_LIBRARY_DIR}")

if(MOSEK_LIBRARY AND NOT TARGET MOSEK::Mosek)
    add_library(MOSEK::Mosek STATIC IMPORTED)
    target_include_directories(MOSEK::Mosek INTERFACE ${MOSEK_INCLUDE_DIR})
    set_target_properties(MOSEK::Mosek PROPERTIES IMPORTED_LOCATION ${MOSEK_LIBRARY})
endif()

find_path(MOSEK_SRC_DIR NAMES "SolverInfo.cc" PATHS "${MOSEK_PLATFORM_PATH}/src/fusion_cxx/")

if(MOSEK_LIBRARY AND MOSEK_SRC_DIR AND NOT TARGET MOSEK::FusionCXX)
    add_library(FusionCXX SHARED EXCLUDE_FROM_ALL
        "${MOSEK_SRC_DIR}/BaseModel.cc"
        "${MOSEK_SRC_DIR}/Debug.cc"
        "${MOSEK_SRC_DIR}/IntMap.cc"
        "${MOSEK_SRC_DIR}/SolverInfo.cc"
        "${MOSEK_SRC_DIR}/StringBuffer.cc"
        "${MOSEK_SRC_DIR}/mosektask.cc"
        "${MOSEK_SRC_DIR}/fusion.cc")
    target_link_libraries(FusionCXX PUBLIC MOSEK::Mosek)
    set_target_properties(FusionCXX PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_compile_features(FusionCXX INTERFACE cxx_std_11)
    target_include_directories(FusionCXX PUBLIC ${MOSEK_SRC_DIR})

    add_library(MOSEK::FusionCXX ALIAS FusionCXX)
endif()

# legacy support:
set(MOSEK_INCLUDE_DIRS ${MOSEK_INCLUDE_DIR})
set(MOSEK_LIBRARIES MOSEK::MosekC MOSEK::FusionCXX)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MOSEK DEFAULT_MSG MOSEK_LIBRARY MOSEK_INCLUDE_DIR)
