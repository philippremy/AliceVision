// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License;
// v. 2.0. If a copy of the MPL was not distributed with this file;
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains declarations of pre-defined algorithms implemented in
 * Apple Metal.
 */

#pragma once

#include <aliceVision/depthMap_mtl/Namespace.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/mvsData/ROI.hpp>

/**
 * NOTE: Any ROI member cannot be const!
 */

ALICEVISION_DEPTHMAP_MTL_NS_START

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_downscaleWithGaussianBlur
 */
struct ArgsDownscaleWithGaussianBlur
{
    const int downscale;
    const int gaussRadius;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_depthSimMapComputeNormal
 */
struct ArgsDepthSimMapComputeNormal
{
    const int out_normalMap_p;
    const int in_depthSimMap_p;
    const int rcDeviceCameraParamsId;
    const int stepXY;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_depthThicknessSmoothThickness
 */
struct ArgsDepthThicknessSmoothThickness
{
    const int inout_depthThicknessMap_p;
    const float minThicknessInflate;
    const float maxThicknessInflate;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeInit_TSim
 */
struct ArgsVolumeInit_TSim
{
    const int inout_volume_s;
    const int inout_volume_p;
    const unsigned int volDimX;
    const unsigned int volDimY;
    const TSim value;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeComputeSimilarity
 */
struct ArgsVolumeComputeSimilarity
{
    const int out_volume1st_s;
    const int out_volume1st_p;
    const int out_volume2nd_s;
    const int out_volume2nd_p;
    const int in_depths_p;
    const int rcDeviceCameraParamsId;
    const int tcDeviceCameraParamsId;
    const unsigned int rcSgmLevelWidth;
    const unsigned int rcSgmLevelHeight;
    const unsigned int tcSgmLevelWidth;
    const unsigned int tcSgmLevelHeight;
    const float rcMipmapLevel;
    const int stepXY;
    const int wsh;
    const float invGammaC;
    const float invGammaP;
    const bool useConsistentScale;
    const bool useCustomPatchPattern;
    Range depthRange;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeUpdateUninitialized
 */
struct ArgsVolumeUpdateUninitialized
{
    const int inout_volume2nd_s;
    const int inout_volume2nd_p;
    const int in_volume1st_s;
    const int in_volume1st_p;
    const unsigned int volDimX;
    const unsigned int volDimY;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeGetVolumeXZSlice_TSimTSimAcc
 */
struct ArgsVolumeGetVolumeXZSliceTSimTSimAcc
{
    const int slice_p;
    const int volume_s;
    const int volume_p;
    int3 volDim;
    int3 axisT;
    const int y;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeInitVolumeYSlice_TSim
 */
struct ArgsVolumeInitVolumeYSlice_TSim
{
    const int volume_s;
    const int volume_p;
    int3 volDim;
    int3 axisT;
    const int y;
    const TSim cst;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeComputeBestZInSlice
 */
struct ArgsVolumeComputeBestZInSlice
{
    const int xzSlice_p;
    const int volDimX;
    const int volDimZ;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeGetVolumeXZSlice_TSimAccTSim
 */
struct ArgsVolumeGetVolumeXZSlice_TSimAccTSim
{
    const int slice_p;
    const int volume_s;
    const int volume_p;
    int3 volDim;
    int3 axisT;
    const int y;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeAggregateCostVolumeAtXInSlices
 */
struct ArgsVolumeAggregateCostVolumeAtXInSlices
{
    const unsigned int rcSgmLevelWidth;
    const unsigned int rcSgmLevelHeight;
    const float rcMipmapLevel;
    int xzSliceForY_p;
    const int xzSliceForYm1_p;
    const int volAgr_s;
    const int volAgr_p;
    int3 volDim;
    int3 axisT;
    const float step;
    const int y;
    const float P1;
    const float _P2;
    const int ySign;
    const int filteringIndex;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeRetrieveBestDepth_DepthSimMap
 */
struct ArgsVolumeRetrieveBestDepth_DepthSimMap
{
    const int out_sgmDepthThicknessMap_p;
    const int out_sgmDepthSimMap_p;
    const int in_depths_p;
    const int in_volSim_s;
    const int in_volSim_p;
    const int rcDeviceCameraParamsId;
    const int volDimZ;  // useful for depth/sim interpolation
    const int scaleStep;
    const float thicknessMultFactor;  // default 1
    const float maxSimilarity;
    Range depthRange;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeRetrieveBestDepth_NoDepthSimMap
 */
struct ArgsVolumeRetrieveBestDepth_NoDepthSimMap
{
    const int out_sgmDepthThicknessMap_p;
    const int in_depths_p;
    const int in_volSim_s;
    const int in_volSim_p;
    const int rcDeviceCameraParamsId;
    const int volDimZ;  // useful for depth/sim interpolation
    const int scaleStep;
    const float thicknessMultFactor;  // default 1
    const float maxSimilarity;
    Range depthRange;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_computeSgmUpscaledDepthPixSizeMap_Bilinear
 */
struct ArgsComputeSgmUpscaledDepthPixSizeMap_Bilinear
{
    const int out_upscaledDepthPixSizeMap_p;
    const int in_sgmDepthThicknessMap_p;
    const int rcDeviceCameraParamsId;  // useful for direct pixSize computation
    const unsigned int rcLevelWidth;
    const unsigned int rcLevelHeight;
    const float rcMipmapLevel;
    const int stepXY;
    const int halfNbDepths;
    const float ratio;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_computeSgmUpscaledDepthPixSizeMap_NearestNeighbor
 */
struct ArgsComputeSgmUpscaledDepthPixSizeMap_NearestNeighbor
{
    const int out_upscaledDepthPixSizeMap_p;
    const int in_sgmDepthThicknessMap_p;
    const int rcDeviceCameraParamsId;  // useful for direct pixSize computation
    const unsigned int rcLevelWidth;
    const unsigned int rcLevelHeight;
    const float rcMipmapLevel;
    const int stepXY;
    const int halfNbDepths;
    const float ratio;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_mapUpscale_float3
 */
struct ArgsMapUpscale_float3
{
    const int out_upscaledMap_p;
    const int in_map_p;
    const float ratio;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_depthSimMapCopyDepthOnly
 */
struct ArgsDepthSimMapCopyDepthOnly
{
    const int out_deptSimMap_p;
    const int in_depthSimMap_p;
    const unsigned int width;
    const unsigned int height;
    const float defaultSim;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeInit_TSimRefine
 */
struct ArgsVolumeInit_TSimRefine
{
    const int inout_volume_s;
    const int inout_volume_p;
    const unsigned int volDimX;
    const unsigned int volDimY;
    const TSimRefine value;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeRefineSimilarity_SgmNormalMap
 */
struct ArgsVolumeRefineSimilarity_SgmNormalMap
{
    const int inout_volSim_s;
    const int inout_volSim_p;
    const int in_sgmDepthPixSizeMap_p;
    const int in_sgmNormalMap_p;
    const int rcDeviceCameraParamsId;
    const int tcDeviceCameraParamsId;
    const unsigned int rcRefineLevelWidth;
    const unsigned int rcRefineLevelHeight;
    const unsigned int tcRefineLevelWidth;
    const unsigned int tcRefineLevelHeight;
    const float rcMipmapLevel;
    const int volDimZ;
    const int stepXY;
    const int wsh;
    const float invGammaC;
    const float invGammaP;
    const bool useConsistentScale;
    const bool useCustomPatchPattern;
    Range depthRange;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeRefineSimilarity_NoSgmNormalMap
 */
struct ArgsVolumeRefineSimilarity_NoSgmNormalMap
{
    const int inout_volSim_s;
    const int inout_volSim_p;
    const int in_sgmDepthPixSizeMap_p;
    const int rcDeviceCameraParamsId;
    const int tcDeviceCameraParamsId;
    const unsigned int rcRefineLevelWidth;
    const unsigned int rcRefineLevelHeight;
    const unsigned int tcRefineLevelWidth;
    const unsigned int tcRefineLevelHeight;
    const float rcMipmapLevel;
    const int volDimZ;
    const int stepXY;
    const int wsh;
    const float invGammaC;
    const float invGammaP;
    const bool useConsistentScale;
    const bool useCustomPatchPattern;
    Range depthRange;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_volumeRefineBestDepth
 */
struct ArgsVolumeRefineBestDepth
{
    const int out_refineDepthSimMap_p;
    const int in_sgmDepthPixSizeMap_p;
    const int in_volSim_s;
    const int in_volSim_p;
    const int volDimZ;
    const int samplesPerPixSize;  // number of subsamples (samples between two depths)
    const int halfNbSamples;      // number of samples (in front and behind mid depth)
    const int halfNbDepths;       // number of depths  (in front and behind mid depth) should be equal to (volDimZ - 1) / 2
    const float twoTimesSigmaPowerTwo;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_optimizeVarLofLABtoW
 */
struct ArgsOptimizeVarLofLABtoW
{
    const int out_varianceMap_p;
    const unsigned int rcLevelWidth;
    const unsigned int rcLevelHeight;
    const float rcMipmapLevel;
    const int stepXY;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_optimizeGetOptDeptMapFromOptDepthSimMap
 */
struct ArgsOptimizeGetOptDeptMapFromOptDepthSimMap
{
    const int out_tmpOptDepthMap_p;
    const int in_optDepthSimMap_p;
    ROI roi;
};

/**
 * @brief Struct which holds the kernel args for:
 *        kernel_optimizeDepthSimMap
 */
struct ArgsOptimizeDepthSimMap
{
    const int out_optimizeDepthSimMap_p;  // output optimized depth/sim map
    const int in_sgmDepthPixSizeMap_p;    // input upscaled rough depth/pixSize map
    const int in_refineDepthSimMap_p;     // input fine depth/sim map
    const int rcDeviceCameraParamsId;
    const int iter;
    ROI roi;
};

ALICEVISION_DEPTHMAP_MTL_NS_END
