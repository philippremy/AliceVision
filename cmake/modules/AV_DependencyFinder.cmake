#
# AV_DependencyFinder.cmake
#
# Finds required dependencies

# Finder Utils
include(AV_DependencyFinderUtils)

av_find_dependency(zlib
  REQUIRED
  TARGETS ZLIB::ZLIB
)

av_find_dependency(OpenMP
  REQUIRED_IF AV_USE_OPENMP
  ALLOW_MODULE
  NO_CONFIG
  COMPONENTS CXX
  TARGETS OpenMP::OpenMP_CXX
)

av_find_dependency(Boost
  REQUIRED
  COMPONENTS
    accumulators
    algorithm
    container
    detail
    filesystem
    foreach
    format
    functional
    geometry
    graph
    headers
    json
    lexical_cast
    log
    math
    multi_array
    multi_index
    program_options
    property_tree
    ptr_container
    range
    regex
    system
    unit_test_framework
  TARGETS
    Boost::accumulators
    Boost::algorithm
    Boost::container
    Boost::detail
    Boost::filesystem
    Boost::foreach
    Boost::format
    Boost::functional
    Boost::geometry
    Boost::graph
    Boost::headers
    Boost::json
    Boost::lexical_cast
    Boost::log
    Boost::math
    Boost::multi_array
    Boost::multi_index
    Boost::program_options
    Boost::property_tree
    Boost::ptr_container
    Boost::range
    Boost::regex
    Boost::system
    Boost::unit_test_framework
)

av_find_dependency(CoinUtils
  REQUIRED
  TARGETS Coin::CoinUtils
)

# Might need to find the OsiMsk target as well
if(AV_USE_MOESK AND DEFINED AV_MOSEK_DIR)
av_find_dependency(Osi
  REQUIRED
  TARGETS Coin::Osi Coin::OsiMsk
)
else()
av_find_dependency(Osi
  REQUIRED
  TARGETS Coin::Osi
)
endif()

av_find_dependency(Clp
  REQUIRED
  TARGETS Coin::Clp
)

av_find_dependency(eigen3
  REQUIRED
  TARGETS Eigen3::Eigen
)

# EXTRA_QUIET: Ceres prints messages from its FindSuiteSparse.cmake module
# Components:
#   - SuiteSparse if AV_USE_CERES_ACCEL_SPARSE and not Apple
#   - Accelerate if AV_USE_CERES_ACCEL_SPARSE and APPLE
if(APPLE AND AV_USE_CERES_ACCEL_SPARSE)
  set(AV_DEP_FIND_Ceres_COMPONENT_ARG COMPONENTS AccelerateSparse)
elseif(NOT APPLE AND AV_USE_CERES_ACCEL_SPARSE)
  set(AV_DEP_FIND_Ceres_COMPONENT_ARG COMPONENTS SuiteSparse)
endif()
av_find_dependency(Ceres
  REQUIRED
  EXTRA_QUIET
  ${AV_DEP_FIND_Ceres_COMPONENT_ARG}
  TARGETS Ceres::ceres
)

av_find_dependency(LEMON
  REQUIRED
  TARGETS LEMON::lemon
)

av_find_dependency(OpenEXR
  REQUIRED
  TARGETS OpenEXR::OpenEXR
)

av_find_dependency(OpenImageIO
  REQUIRED
  TARGETS OpenImageIO::OpenImageIO
)

av_find_dependency(OpenCV
  REQUIRED_IF AV_USE_OPENCV
  COMPONENTS
    core
    imgproc
    video
    imgcodecs
    videoio
    features2d
    optflow
    photo
  TARGETS
    opencv_core
    opencv_imgproc
    opencv_imgcodecs
    opencv_videoio
    opencv_features2d
    opencv_optflow
    opencv_photo
)

av_find_dependency(OpenCV
  REQUIRED_IF AV_USE_OPENCV_CONTRIB
  COMPONENTS
    mcc
  TARGETS
    opencv_mcc
)

av_find_dependency(Expat
  REQUIRED
  TARGETS expat::expat
)

av_find_dependency(VLFeat
  REQUIRED
  TARGETS VLFeat::VL
)

av_find_dependency(CCTag
  REQUIRED_IF AV_USE_CCTAG
  TARGETS CCTag::CCTag
)

av_find_dependency(Apriltag
  REQUIRED_IF AV_USE_APRILTAG
  TARGETS apriltag::apriltag
)

av_find_dependency(PopSift
  REQUIRED_IF AV_USE_POPSIFT
  TARGETS PopSift::PopSift
)

av_find_dependency(UncertaintyTE
  REQUIRED_IF AV_USE_UNCERTAINTYTE
  TARGETS UncertaintyTE::UncertaintyTE
)

av_find_dependency(ONNXRuntime
  REQUIRED_IF AV_USE_ONNX
  NO_CONFIG
  ALLOW_MODULE
  MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules/find_modules"
  TARGETS ONNXRuntime::ONNXRuntime
)

av_find_dependency(nanoflann
  REQUIRED
  TARGETS nanoflann::nanoflann
)

av_find_dependency(flann
  REQUIRED
  SHARED_TARGETS flann::flann_cpp
  STATIC_TARGETS flann::flann_cpp_s
)

# Geogram has no Config file and instead provides a custom
# FindGeogram.cmake module, which we pass here explicitly
av_find_dependency(Geogram
  REQUIRED
  NO_CONFIG
  ALLOW_MODULE
  MODULE_PATH ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/modules
  TARGETS Geogram::geogram
)

av_find_dependency(Alembic
  REQUIRED_IF AV_USE_ALEMBIC
  TARGETS Alembic::Alembic
)

av_find_dependency(Assimp
  REQUIRED
  TARGETS assimp::assimp
)

av_find_dependency(E57Format
  REQUIRED
  TARGETS E57Format
)

av_find_dependency(pxr
  REQUIRED_IF AV_USE_USD
  TARGETS
    usd
    usdGeom
    usdImaging
    usdShade
    gf
    tf
    vt
    sdf
)

av_find_dependency(MOSEK
  REQUIRED_IF AV_USE_MOSEK
  NO_CONFIG
  ALLOW_MODULE
  MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules/find_modules"
  TARGETS MOSEK::Mosek
)

av_find_dependency(MeshSDFilter
  REQUIRED_IF AV_USE_MESHSDFILTER
  TARGETS MeshSDFilter::MeshSDLibrary
)
