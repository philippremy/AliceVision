# Adds a single interface library which exposes the two third party headers

# TODO: Must be exported later, because it is used by headers
add_library(aliceVision_thirdParty
  INTERFACE
)

target_include_directories(aliceVision_thirdParty
  INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
