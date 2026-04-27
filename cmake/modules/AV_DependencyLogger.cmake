# =========================
# Dependency Configuration
# =========================

# ---- Section Lists (example placeholders; replace with real deps) ----
set(AV_DEP_GROUP_CORE
  OpenMP
  zlib
  Boost
)

set(AV_DEP_GROUP_MATH
  MOSEK
  CoinUtils
  CoinOsi
  CoinClp
  Eigen3
  Ceres
  LEMON

)

set(AV_DEP_GROUP_IMAGE
  OpenEXR
  OpenImageIO
  OpenCV
  OpenCVContrib
)

set(AV_DEP_GROUP_UTILITY
  Expat
)

set(AV_DEP_GROUP_FEATURE_EXTRACTION
  VLFeat
  CCTag
  AprilTag
  PopSIFT
)

set(AV_DEP_GROUP_ALGORITHM
  UncertaintyTE
  nanoflann
  flann
)

set(AV_DEP_GROUP_GEOMETRY
  Geogram
  MeshSDFilter
)

set(AV_DEP_GROUP_ASSET
  USD
  Alembic
  Assimp
  E57Format
)

set(AV_DEP_GROUP_TRANSITIVE
  lz4
  brotli
  BLAS-LAPACK
  IMath
  OpenJPH
  libTIFF
  OpenColorIO
  JPEG-Turbo
  libPNG
  libRAW
  ffmpeg
  OpenJPEG
  oneTBB
  GIFLIB
  libWebP
  JPEG-XL
  JBIG
  Gflags
  Magma
  XercesC
  OpenMesh
)

# ---- Helper: print one dependency line ----
function(_av_print_dep_line DEP_NAME WIDTH)
  set(disabled_var "AV_DEP_${DEP_NAME}_DISABLED")
  set(disabled_reason_var "AV_DEP_${DEP_NAME}_DISABLED_REASON")
  set(no_build_var "AV_DEP_${DEP_NAME}_NO_BUILD")
  set(no_build_reason_var "AV_DEP_${DEP_NAME}_NO_BUILD_REASON")

  if(DEFINED ${disabled_var})
    set(state_icon "☒")
    set(state_color "R")
    if(DEFINED ${disabled_reason_var})
      set(reason "${${disabled_reason_var}}")
    else()
      set(reason "disabled by configuration")
    endif()
  else()
    # enabled: decide build vs no-build
    if(DEFINED ${no_build_var})
      set(state_icon "☐")
      set(state_color "Y")
      if(DEFINED ${no_build_reason_var})
        set(reason "${${no_build_reason_var}}")
      else()
        set(reason "use system/externally provided")
      endif()
    else()
      set(state_icon "☑")
      set(state_color "G")
      set(reason "will be built")
    endif()
  endif()

  # padding for compact alignment
  string(LENGTH "${DEP_NAME}" name_len)
  math(EXPR pad "${WIDTH} - ${name_len}")
  if(pad LESS 1)
    set(pad 1)
  endif()
  string(REPEAT " " ${pad} spacing)

  av_colored_message(PLAIN ${state_color} "  ${state_icon}" ! " ${DEP_NAME}${spacing}" W "(${reason})")
endfunction()

# ---- Print one dependency group ----
function(av_print_dependency_group GROUP_TITLE GROUP_LIST)
  set(width 30)
  av_colored_message(PLAIN W "===" B " ${GROUP_TITLE} " W "===")
  av_colored_message(PLAIN "")

  foreach(dep IN LISTS ${GROUP_LIST})
    _av_print_dep_line("${dep}" ${width})
  endforeach()

  av_colored_message(PLAIN "")
endfunction()

# ---- Summary entry point ----
av_colored_message(PLAIN Y "============ Dependency Summary ============")
av_colored_message(PLAIN "")

av_print_dependency_group("Core Dependencies"                     AV_DEP_GROUP_CORE)
av_print_dependency_group("Algorithm Dependencies"                AV_DEP_GROUP_ALGORITHM)
av_print_dependency_group("Math Dependencies"                     AV_DEP_GROUP_MATH)
av_print_dependency_group("Image Dependencies"                    AV_DEP_GROUP_IMAGE)
av_print_dependency_group("Utility Dependencies"                  AV_DEP_GROUP_UTILITY)
av_print_dependency_group("Marker Detection Dependencies"         AV_DEP_GROUP_FEATURE_EXTRACTION)
av_print_dependency_group("Geometry Dependencies"                 AV_DEP_GROUP_GEOMETRY)
av_print_dependency_group("Asset Depenencies"                     AV_DEP_GROUP_ASSET)
av_print_dependency_group("Transitive Dependencies (indirect)"    AV_DEP_GROUP_TRANSITIVE)

av_colored_message(PLAIN Y "=============================================")
