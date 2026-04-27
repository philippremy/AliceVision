# ===============================================
# Generate config.hpp
# ===============================================
configure_file(
  ${CMAKE_SOURCE_DIR}/cmake/templates/config.hpp.in
  ${CMAKE_BINARY_DIR}/generated/aliceVision/config.hpp
)

# Add third party code (just one interface library)
add_subdirectory(third_party)

# Add AliceVision
add_subdirectory(aliceVision)

# Add software, if required
if(AV_BUILD_SOFTWARE)
  add_subdirectory(software)
endif()
