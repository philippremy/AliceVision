// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Config.h>
#include <aliceVision/depthMap_mtl/Namespace.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/depthMap_mtl/private/DeviceCameraParams.hpp>
#include <aliceVision/depthMap_mtl/private/KernelArgs.hpp>

/* Metal Headers */
#include <aliceVision/depthMap_mtl/metal/Buffer.hpp>
#include <aliceVision/depthMap_mtl/metal/Math.hpp>
#include <aliceVision/depthMap_mtl/metal/Patch.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

#pragma mark Freestanding Functions

inline void
volume_computePatch(thread Patch& patch,
                    constant const DeviceCameraParams& rcDeviceCamParams,
                    constant const DeviceCameraParams& tcDeviceCamParams,
                    const float fpPlaneDepth,
                    thread const float2& pix)
{
    patch.p = get3DPointForPixelAndFrontoParellePlaneRC(rcDeviceCamParams, pix, fpPlaneDepth);
    patch.d = computePixSize(rcDeviceCamParams, patch.p);
    computeRotCSEpip(patch, rcDeviceCamParams, tcDeviceCamParams);
}

inline float
depthPlaneToDepth(constant const DeviceCameraParams& deviceCamParams,
                  const float fpPlaneDepth,
                  thread const float2& pix)
{
    const float3 planep = deviceCamParams.C + deviceCamParams.ZVect * fpPlaneDepth;
    float3 v = M3x3mulV2(deviceCamParams.iP, pix);
    av_normalize(v);
    float3 p = linePlaneIntersect(deviceCamParams.C, v, planep, deviceCamParams.ZVect);
    return av_size(deviceCamParams.C - p);
}

inline void move3DPointByRcPixSize(thread float3& p,
                                   constant const DeviceCameraParams& rcDeviceCamParams,
                                   const float rcPixSize)
{
    float3 rpv = p - rcDeviceCamParams.C;
    av_normalize(rpv);
    p = p + rpv * rcPixSize;
}

#pragma mark Kernels

[[kernel]] void
kernel_volumeInit_TSim(device TSim* inout_volume_d [[buffer(0)]],
                       constant const ArgsVolumeInit_TSim& kernelArgs [[buffer(30)]],
                       const uint3 gid [[thread_position_in_grid]],
                       const uint3 blockIdx [[threadgroup_position_in_grid]])
{
    const unsigned int vx = gid.x;
    const unsigned int vy = gid.y;
    const unsigned int vz = blockIdx.z;

    if(vx >= kernelArgs.volDimX || vy >= kernelArgs.volDimY)
        return;

    *get3DBufferAtDevice(inout_volume_d, kernelArgs.inout_volume_s, kernelArgs.inout_volume_p, vx, vy, vz) = kernelArgs.value;
}

[[kernel]] void
kernel_volumeInit_TSimRefine(device TSimRefine* inout_volume_d [[buffer(0)]],
                             constant const ArgsVolumeInit_TSimRefine& kernelArgs [[buffer(30)]],
                             const uint3 gid [[thread_position_in_grid]],
                             const uint3 blockIdx [[threadgroup_position_in_grid]])
{
    const unsigned int vx = gid.x;
    const unsigned int vy = gid.y;
    const unsigned int vz = blockIdx.z;

    if(vx >= kernelArgs.volDimX || vy >= kernelArgs.volDimY)
        return;

    *get3DBufferAtDevice(inout_volume_d, kernelArgs.inout_volume_s, kernelArgs.inout_volume_p, vx, vy, vz) = kernelArgs.value;
}

[[kernel]] void
kernel_volumeComputeSimilarity(device TSim* out_volume1st_d [[buffer(0)]],
                               device TSim* out_volume2nd_d [[buffer(1)]],
                               constant const float* in_depths_d [[buffer(2)]],
                               const texture2d<MTLRGBABaseType, access::sample> rcMipmapImage_tex [[texture(0)]],
                               const texture2d<MTLRGBABaseType, access::sample> tcMipmapImage_tex [[texture(1)]],
                               constant const DeviceCameraParams* constantCameraParametersArray_d [[buffer(28)]], // Extra DeviceCameraParams as push constant
                               constant const DevicePatchPattern& constantPatchPattern_d [[buffer(29)]],    // Extra DevicePatchPattern as push constant
                               constant const ArgsVolumeComputeSimilarity& kernelArgs [[buffer(30)]],
                               const uint3 gid [[thread_position_in_grid]],
                               const uint3 blockIdx [[threadgroup_position_in_grid]])
{
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;
    const unsigned int roiZ = blockIdx.z;

    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height()) // no need to check roiZ
        return;

    // R and T camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];
    constant const DeviceCameraParams& tcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.tcDeviceCameraParamsId];

    // corresponding volume coordinates
    const unsigned int vx = roiX;
    const unsigned int vy = roiY;
    const unsigned int vz = kernelArgs.depthRange.begin + roiZ;

    // corresponding image coordinates
    const float x = float(roi.x.begin + vx) * float(kernelArgs.stepXY);
    const float y = float(roi.y.begin + vy) * float(kernelArgs.stepXY);

    // corresponding depth plane
    const float depthPlane = BufPtrConstant<float>(in_depths_d, kernelArgs.in_depths_p).at(size_t(vz), 0);

    Patch patch;
    volume_computePatch(patch, rcDeviceCamParams, tcDeviceCamParams, depthPlane, float2(x, y));

    // we do not need positive and filtered similarity values
    constexpr bool invertAndFilter = false;

    // NOTE: This differs from CUDA, because we use -ffast-math and cannot
    //       rely on INFINITY. Instead, use MAXFLOAT for the invalid value.
    float fsim = MAXFLOAT;

    if(kernelArgs.useCustomPatchPattern) {
        fsim = compNCCby3DptsYK_customPatchPattern<invertAndFilter>(rcDeviceCamParams,
                                                                    tcDeviceCamParams,
                                                                    rcMipmapImage_tex,
                                                                    tcMipmapImage_tex,
                                                                    kernelArgs.rcSgmLevelWidth,
                                                                    kernelArgs.rcSgmLevelHeight,
                                                                    kernelArgs.tcSgmLevelWidth,
                                                                    kernelArgs.tcSgmLevelHeight,
                                                                    kernelArgs.rcMipmapLevel,
                                                                    kernelArgs.invGammaC,
                                                                    kernelArgs.invGammaP,
                                                                    kernelArgs.useConsistentScale,
                                                                    patch,
                                                                    constantPatchPattern_d);
    } else {
        fsim = compNCCby3DptsYK<invertAndFilter>(rcDeviceCamParams,
                                                 tcDeviceCamParams,
                                                 rcMipmapImage_tex,
                                                 tcMipmapImage_tex,
                                                 kernelArgs.rcSgmLevelWidth,
                                                 kernelArgs.rcSgmLevelHeight,
                                                 kernelArgs.tcSgmLevelWidth,
                                                 kernelArgs.tcSgmLevelHeight,
                                                 kernelArgs.rcMipmapLevel,
                                                 kernelArgs.wsh,
                                                 kernelArgs.invGammaC,
                                                 kernelArgs.invGammaP,
                                                 kernelArgs.useConsistentScale,
                                                 patch);
    }

    if(fsim == MAXFLOAT) // invalid similarity
    {
      fsim = 255.0f; // 255 is the invalid similarity value
    }
    else // valid similarity
    {
      // remap similarity value
      constexpr const float fminVal = -1.0f;
      constexpr const float fmaxVal = 1.0f;
      constexpr const float fmultiplier = 1.0f / (fmaxVal - fminVal);

      fsim = (fsim - fminVal) * fmultiplier;

#ifdef ALICEVISION_DEPTHMAP_TSIM_USE_FLOAT
      // no clamp
#else
      fsim = min(1.0f, max(0.0f, fsim));
#endif
      // convert from (0, 1) to (0, 254)
      // needed to store in the volume in uchar
      // 255 is reserved for the similarity initialization, i.e. undefined values
      fsim *= 254.0f;
    }

    device TSim* fsim_1st = get3DBufferAtDevice(out_volume1st_d, kernelArgs.out_volume1st_s, kernelArgs.out_volume1st_p, size_t(vx), size_t(vy), size_t(vz));
    device TSim* fsim_2nd = get3DBufferAtDevice(out_volume2nd_d, kernelArgs.out_volume2nd_s, kernelArgs.out_volume2nd_p, size_t(vx), size_t(vy), size_t(vz));

    if(fsim < *fsim_1st)
    {
        *fsim_2nd = *fsim_1st;
        *fsim_1st = TSim(fsim);
    }
    else if(fsim < *fsim_2nd)
    {
        *fsim_2nd = TSim(fsim);
    }
}

[[kernel]] void
kernel_volumeUpdateUninitialized(device TSim* inout_volume2nd_d [[buffer(0)]],
                                 constant const TSim* in_volume1st_d [[buffer(1)]],
                                 constant const ArgsVolumeUpdateUninitialized& kernelArgs [[buffer(30)]],
                                 const uint3 gid [[thread_position_in_grid]],
                                 const uint3 blockIdx [[threadgroup_position_in_grid]])
{
    const unsigned int vx = gid.x;
    const unsigned int vy = gid.y;
    const unsigned int vz = blockIdx.z;

    if(vx >= kernelArgs.volDimX || vy >= kernelArgs.volDimY)
        return;

    // input/output second best similarity value
    device TSim* inout_simPtr = get3DBufferAtDevice(inout_volume2nd_d, kernelArgs.inout_volume2nd_s, kernelArgs.inout_volume2nd_p, vx, vy, vz);

    if(*inout_simPtr >= 255.f) // invalid or uninitialized similarity value
    {
        // update second best similarity value with first best similarity value
        *inout_simPtr = *get3DBufferAtConstant(in_volume1st_d, kernelArgs.in_volume1st_s, kernelArgs.in_volume1st_p, vx, vy, vz);
    }
}


[[kernel]] void
kernel_volumeGetVolumeXZSlice_TSimTSimAcc(device TSim* slice_d [[buffer(0)]],
                                          constant const TSimAcc* volume_d [[buffer(1)]],
                                          constant const ArgsVolumeGetVolumeXZSliceTSimTSimAcc& kernelArgs [[buffer(30)]],
                                          const uint3 gid [[thread_position_in_grid]])
{
    const int x = gid.x;
    const int z = gid.y;

    int3 v;

    switch (kernelArgs.axisT.x) {
        case 0: v.x = x; break;
        case 1: v.y = x; break;
        case 2: v.z = x; break;
    }

    switch (kernelArgs.axisT.y) {
        case 0: v.x = kernelArgs.y; break;
        case 1: v.y = kernelArgs.y; break;
        case 2: v.z = kernelArgs.y; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: v.x = z; break;
        case 1: v.y = z; break;
        case 2: v.z = z; break;
    }

    int dimX, dimZ;

    switch (kernelArgs.axisT.x) {
        case 0: dimX = kernelArgs.volDim.x; break;
        case 1: dimX = kernelArgs.volDim.y; break;
        case 2: dimX = kernelArgs.volDim.z; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: dimZ = kernelArgs.volDim.x; break;
        case 1: dimZ = kernelArgs.volDim.y; break;
        case 2: dimZ = kernelArgs.volDim.z; break;
    }

    if (x >= dimX || z >= dimZ)
        return;

    constant const TSimAcc* volume_xyz = get3DBufferAtConstant(volume_d, kernelArgs. volume_s, kernelArgs.volume_p, v.x, v.y, v.z);

    device TSim& slice_xz = BufPtrDevice<TSim>(slice_d, kernelArgs.slice_p).at(x, z);
    slice_xz = (TSim)(*volume_xyz);
}

[[kernel]] void
kernel_volumeInitVolumeYSlice_TSim(device TSim* volume_d [[buffer(0)]],
                                   constant const ArgsVolumeInitVolumeYSlice_TSim& kernelArgs [[buffer(30)]],
                                   const uint3 gid [[thread_position_in_grid]])
{
    const int x = gid.x;
    const int z = gid.y;

    int3 v;

    switch (kernelArgs.axisT.x) {
        case 0: v.x = x; break;
        case 1: v.y = x; break;
        case 2: v.z = x; break;
    }

    switch (kernelArgs.axisT.y) {
        case 0: v.x = kernelArgs.y; break;
        case 1: v.y = kernelArgs.y; break;
        case 2: v.z = kernelArgs.y; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: v.x = z; break;
        case 1: v.y = z; break;
        case 2: v.z = z; break;
    }

    int dimX, dimZ;

    switch (kernelArgs.axisT.x) {
        case 0: dimX = kernelArgs.volDim.x; break;
        case 1: dimX = kernelArgs.volDim.y; break;
        case 2: dimX = kernelArgs.volDim.z; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: dimZ = kernelArgs.volDim.x; break;
        case 1: dimZ = kernelArgs.volDim.y; break;
        case 2: dimZ = kernelArgs.volDim.z; break;
    }

    if ((x >= 0) && (x < dimX) &&
        (z >= 0) && (z < dimZ))
    {
        device TSim* volume_zyx = get3DBufferAtDevice(volume_d, kernelArgs.volume_s, kernelArgs.volume_p,
                                     v.x, v.y, v.z);
        *volume_zyx = kernelArgs.cst;
    }
}

[[kernel]] void
kernel_volumeComputeBestZInSlice(device TSimAcc* xzSlice_d [[buffer(0)]],
                                 device TSimAcc*  ySliceBestInColCst_d [[buffer(1)]],
                                 constant const ArgsVolumeComputeBestZInSlice& kernelArgs [[buffer(30)]],
                                 const uint3 gid [[thread_position_in_grid]])
{
    const int x = gid.x;

    if(x >= kernelArgs.volDimX)
        return;

    device TSimAcc& bestCst = BufPtrDevice<TSimAcc>(xzSlice_d, kernelArgs.xzSlice_p).at(x, 0);

    for(int z = 1; z < kernelArgs.volDimZ; ++z)
    {
        const TSimAcc cst = BufPtrDevice<TSimAcc>(xzSlice_d, kernelArgs.xzSlice_p).at(x, z);
        bestCst = cst < bestCst ? cst : bestCst;  // min(cst, bestCst);
    }
    ySliceBestInColCst_d[x] = bestCst;
}

[[kernel]] void
kernel_volumeGetVolumeXZSlice_TSimAccTSim(device TSimAcc* slice_d [[buffer(0)]],
                                          constant const TSim* volume_d [[buffer(1)]],
                                          constant const ArgsVolumeGetVolumeXZSlice_TSimAccTSim& kernelArgs [[buffer(30)]],
                                          const uint3 gid [[thread_position_in_grid]])
{
    const int x = gid.x;
    const int z = gid.y;

    int3 v;

    switch (kernelArgs.axisT.x) {
        case 0: v.x = x; break;
        case 1: v.y = x; break;
        case 2: v.z = x; break;
    }

    switch (kernelArgs.axisT.y) {
        case 0: v.x = kernelArgs.y; break;
        case 1: v.y = kernelArgs.y; break;
        case 2: v.z = kernelArgs.y; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: v.x = z; break;
        case 1: v.y = z; break;
        case 2: v.z = z; break;
    }

    int dimX, dimZ;

    switch (kernelArgs.axisT.x) {
        case 0: dimX = kernelArgs.volDim.x; break;
        case 1: dimX = kernelArgs.volDim.y; break;
        case 2: dimX = kernelArgs.volDim.z; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: dimZ = kernelArgs.volDim.x; break;
        case 1: dimZ = kernelArgs.volDim.y; break;
        case 2: dimZ = kernelArgs.volDim.z; break;
    }

    if (x >= dimX || z >= dimZ)
        return;

    constant const TSim* volume_xyz = get3DBufferAtConstant(volume_d, kernelArgs.volume_s, kernelArgs.volume_p, v.x, v.y, v.z);
    device TSimAcc& slice_xz = BufPtrDevice<TSimAcc>(slice_d, kernelArgs.slice_p).at(x, z);
    slice_xz = (TSimAcc)(*volume_xyz);
}

/**
 * @param[inout] xySliceForZ input similarity plane
 * @param[in] xySliceForZM1
 * @param[in] xSliceBestInColCst
 * @param[out] volSimT output similarity volume
 */
[[kernel]] void
kernel_volumeAggregateCostVolumeAtXInSlices(const texture2d<MTLRGBABaseType, access::sample> rcMipmapImage_tex [[texture(0)]],
                                            device TSimAcc* xzSliceForY_d [[buffer(0)]],
                                            constant const TSimAcc* xzSliceForYm1_d [[buffer(1)]],
                                            constant const TSimAcc* bestSimInYm1_d [[buffer(2)]],
                                            device TSim* volAgr_d [[buffer(3)]],
                                            constant const ArgsVolumeAggregateCostVolumeAtXInSlices& kernelArgs [[buffer(30)]],
                                            const uint3 gid [[thread_position_in_grid]])
{
    const int x = gid.x;
    const int z = gid.y;

    int3 v;

    switch (kernelArgs.axisT.x) {
        case 0: v.x = x; break;
        case 1: v.y = x; break;
        case 2: v.z = x; break;
    }

    switch (kernelArgs.axisT.y) {
        case 0: v.x = kernelArgs.y; break;
        case 1: v.y = kernelArgs.y; break;
        case 2: v.z = kernelArgs.y; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: v.x = z; break;
        case 1: v.y = z; break;
        case 2: v.z = z; break;
    }

    int dimX, dimZ;

    switch (kernelArgs.axisT.x) {
        case 0: dimX = kernelArgs.volDim.x; break;
        case 1: dimX = kernelArgs.volDim.y; break;
        case 2: dimX = kernelArgs.volDim.z; break;
    }

    switch (kernelArgs.axisT.z) {
        case 0: dimZ = kernelArgs.volDim.x; break;
        case 1: dimZ = kernelArgs.volDim.y; break;
        case 2: dimZ = kernelArgs.volDim.z; break;
    }

    if (x >= dimX || z >= dimZ)
        return;

    // find texture offset
    const int beginX = (kernelArgs.axisT.x == 0) ? kernelArgs.roi.x.begin : kernelArgs.roi.y.begin;
    const int beginY = (kernelArgs.axisT.x == 0) ? kernelArgs.roi.y.begin : kernelArgs.roi.x.begin;

    device TSimAcc& sim_xz = BufPtrDevice<TSimAcc>(xzSliceForY_d, kernelArgs.xzSliceForY_p).at(x, z);
    float pathCost = 255.0f;

    if((z >= 1) && (z < kernelArgs.volDim.z - 1))
    {
        float P2 = 0;

        if(kernelArgs._P2 < 0)
        {
          // _P2 convention: use negative value to skip the use of deltaC.
          P2 = abs(kernelArgs._P2);
        }
        else
        {
          const int imX0 = (beginX + v.x) * kernelArgs.step; // current
          const int imY0 = (beginY + v.y) * kernelArgs.step;

          const int imX1 = imX0 - kernelArgs.ySign * kernelArgs.step * (kernelArgs.axisT.y == 0); // M1
          const int imY1 = imY0 - kernelArgs.ySign * kernelArgs.step * (kernelArgs.axisT.y == 1);

          const float4 gcr0 = float4(rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((float(imX0) + 0.5f) / float(kernelArgs.rcSgmLevelWidth), (float(imY0) + 0.5f) / float(kernelArgs.rcSgmLevelHeight)), kernelArgs.rcMipmapLevel));
          const float4 gcr1 = float4(rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((float(imX1) + 0.5f) / float(kernelArgs.rcSgmLevelWidth), (float(imY1) + 0.5f) / float(kernelArgs.rcSgmLevelHeight)), kernelArgs.rcMipmapLevel));
          const float deltaC = euclideanDist3(gcr0, gcr1);

          // sigmoid f(x) = i + (a - i) * (1 / ( 1 + e^(10 * (x - P2) / w)))
          // see: https://www.desmos.com/calculator/1qvampwbyx
          // best values found from tests: i = 80, a = 255, w = 80, P2 = 100
          // historical values: i = 15, a = 255, w = 80, P2 = 20
          P2 = av_sigmoid(80.f, 255.f, 80.f, kernelArgs._P2, deltaC);
        }

        const TSimAcc bestCostInColM1 = bestSimInYm1_d[x];
        const TSimAcc pathCostMDM1 = BufPtrConstant<TSimAcc>(xzSliceForYm1_d, kernelArgs.xzSliceForYm1_p).at(x, z - 1); // M1: minus 1 over depths
        const TSimAcc pathCostMD   = BufPtrConstant<TSimAcc>(xzSliceForYm1_d, kernelArgs.xzSliceForYm1_p).at(x, z);
        const TSimAcc pathCostMDP1 = BufPtrConstant<TSimAcc>(xzSliceForYm1_d, kernelArgs.xzSliceForYm1_p).at(x, z + 1); // P1: plus 1 over depths
        const float minCost = av_multi_min(pathCostMD, pathCostMDM1 + kernelArgs.P1, pathCostMDP1 + kernelArgs.P1, bestCostInColM1 + P2);

        // if 'pathCostMD' is the minimal value of the depth
        pathCost = sim_xz + minCost - bestCostInColM1;
    }

    // fill the current slice with the new similarity score
    sim_xz = TSimAcc(pathCost);

#ifndef TSIM_USE_FLOAT
    // clamp if TSim = uchar (TSimAcc = unsigned int)
    pathCost = min(255.0f, max(0.0f, pathCost));
#endif

    // aggregate into the final output
    device TSim* volume_xyz = get3DBufferAtDevice(volAgr_d, kernelArgs.volAgr_s, kernelArgs.volAgr_p, v.x, v.y, v.z);
    const float val = (float(*volume_xyz) * float(kernelArgs.filteringIndex) + pathCost) / float(kernelArgs.filteringIndex + 1);
    *volume_xyz = TSim(val);
}

[[kernel]] void
kernel_volumeRetrieveBestDepth_DepthSimMap(device float2* out_sgmDepthThicknessMap_d [[buffer(0)]],
                                           device float2* out_sgmDepthSimMap_d [[buffer(1)]], // With depth sim map
                                           constant const float* in_depths_d [[buffer(2)]],
                                           constant const TSim* in_volSim_d [[buffer(3)]],
                                           constant const DeviceCameraParams* constantCameraParametersArray_d [[buffer(29)]], // Extra DeviceCameraParams as push constant
                                           constant const ArgsVolumeRetrieveBestDepth_DepthSimMap& kernelArgs [[buffer(30)]],
                                           const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int vx = gid.x;
    const unsigned int vy = gid.y;

    /* Make available */
    const auto roi = kernelArgs.roi;

    if(vx >= roi.width() || vy >= roi.height())
        return;

    // R camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];

    // corresponding image coordinates
    const float2 pix{float((kernelArgs.roi.x.begin + vx) * kernelArgs.scaleStep), float((kernelArgs.roi.y.begin + vy) * kernelArgs.scaleStep)};

    // corresponding output depth/thickness pointer
    device float2& out_bestDepthThicknessPtr = BufPtrDevice<float2>(out_sgmDepthThicknessMap_d, kernelArgs.out_sgmDepthThicknessMap_p).at(vx, vy);

    // corresponding output depth/sim pointer or nullptr
    device float2& out_bestDepthSimPtr = BufPtrDevice<float2>(out_sgmDepthSimMap_d, kernelArgs.out_sgmDepthSimMap_p).at(vx, vy);

    // find the best depth plane index for the current pixel
    // the best depth plane has the best similarity value
    // - best possible similarity value is 0
    // - worst possible similarity value is 254
    // - invalid similarity value is 255
    float bestSim = 255.f;
    int bestZIdx = -1;

    for(unsigned int vz = kernelArgs.depthRange.begin; vz < kernelArgs.depthRange.end; ++vz)
    {
      const float simAtZ = *get3DBufferAtConstant(in_volSim_d, kernelArgs.in_volSim_s, kernelArgs.in_volSim_p, vx, vy, vz);

      if(simAtZ < bestSim)
      {
        bestSim = simAtZ;
        bestZIdx = vz;
      }
    }

    // filtering out invalid values and values with a too bad score (above the user maximum similarity threshold)
    // note: this helps to reduce following calculations and also the storage volume of the depth maps.
    if((bestZIdx == -1) || (bestSim > kernelArgs.maxSimilarity))
    {
        out_bestDepthThicknessPtr.x = -1.f; // invalid depth
        out_bestDepthThicknessPtr.y = -1.f; // invalid thickness

        out_bestDepthSimPtr.x = -1.f; // invalid depth
        out_bestDepthSimPtr.y =  1.f; // worst similarity value

        return;
    }

    // find best depth plane previous and next indexes
    const int bestZIdx_m1 = max(0, bestZIdx - 1);           // best depth plane previous index
    const int bestZIdx_p1 = min(kernelArgs.volDimZ - 1, bestZIdx + 1); // best depth plane next index

    // get best best depth current, previous and next plane depth values
    // note: float3 struct is useful for depth interpolation
    float3 depthPlanes;
    depthPlanes.x = BufPtrConstant<float>(in_depths_d, kernelArgs.in_depths_p).at(bestZIdx_m1, 0);  // best depth previous plane
    depthPlanes.y = BufPtrConstant<float>(in_depths_d, kernelArgs.in_depths_p).at(bestZIdx, 0);     // best depth plane
    depthPlanes.z = BufPtrConstant<float>(in_depths_d, kernelArgs.in_depths_p).at(bestZIdx_p1, 0);  // best depth next plane

    const float bestDepth    = depthPlaneToDepth(rcDeviceCamParams, depthPlanes.y, pix); // best depth
    const float bestDepth_m1 = depthPlaneToDepth(rcDeviceCamParams, depthPlanes.x, pix); // previous best depth
    const float bestDepth_p1 = depthPlaneToDepth(rcDeviceCamParams, depthPlanes.z, pix); // next best depth

#ifdef ALICEVISION_DEPTHMAP_RETRIEVE_BEST_Z_INTERPOLATION
    // with depth/sim interpolation
    // note: disable by default

    float3 sims;
    sims.x = *get3DBufferAtConstant(in_volSim_d, kernelArgs.in_volSim_s, kernelArgs.in_volSim_p, vx, vy, bestZIdx_m1);
    sims.y = bestSim;
    sims.z = *get3DBufferAtConstant(in_volSim_d, kernelArgs.in_volSim_s, kernelArgs.in_volSim_p, vx, vy, bestZIdx_p1);

    // convert sims from (0, 255) to (-1, +1)
    sims.x = (sims.x / 255.0f) * 2.0f - 1.0f;
    sims.y = (sims.y / 255.0f) * 2.0f - 1.0f;
    sims.z = (sims.z / 255.0f) * 2.0f - 1.0f;

    // interpolation between the 3 depth planes candidates
    const float refinedDepthPlane = refineDepthSubPixel(depthPlanes, sims);

    const float out_bestDepth = depthPlaneToDepth(rcDeviceCamParams, refinedDepthPlane, pix);
    const float out_bestSim = sims.y;
#else
    // without depth interpolation
    const float out_bestDepth = bestDepth;
    const float out_bestSim = (bestSim / 255.0f) * 2.0f - 1.0f; // convert from (0, 255) to (-1, +1)
#endif

    // compute output best depth thickness
    // thickness is the maximum distance between output best depth and previous or next depth
    // thickness can be inflate with thicknessMultFactor
    const float out_bestDepthThickness = max(bestDepth_p1 - out_bestDepth, out_bestDepth - bestDepth_m1) * kernelArgs.thicknessMultFactor;

    // write output depth/thickness
    out_bestDepthThicknessPtr.x = out_bestDepth;
    out_bestDepthThicknessPtr.y = out_bestDepthThickness;

    // write output depth/sim
    out_bestDepthSimPtr.x = out_bestDepth;
    out_bestDepthSimPtr.y = out_bestSim;
}

[[kernel]] void
kernel_volumeRetrieveBestDepth_NoDepthSimMap(device float2* out_sgmDepthThicknessMap_d [[buffer(0)]],
                                             constant const float* in_depths_d [[buffer(1)]],
                                             constant const TSim* in_volSim_d [[buffer(2)]],
                                             constant const DeviceCameraParams* constantCameraParametersArray_d [[buffer(29)]], // Extra DeviceCameraParams as push constant
                                             constant const ArgsVolumeRetrieveBestDepth_NoDepthSimMap& kernelArgs [[buffer(30)]],
                                             const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int vx = gid.x;
    const unsigned int vy = gid.y;

    /* Make available */
    const auto roi = kernelArgs.roi;

    if(vx >= roi.width() || vy >= roi.height())
        return;

    // R camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];

    // corresponding image coordinates
    const float2 pix{float((kernelArgs.roi.x.begin + vx) * kernelArgs.scaleStep), float((kernelArgs.roi.y.begin + vy) * kernelArgs.scaleStep)};

    // corresponding output depth/thickness pointer
    device float2& out_bestDepthThicknessPtr = BufPtrDevice<float2>(out_sgmDepthThicknessMap_d, kernelArgs.out_sgmDepthThicknessMap_p).at(vx, vy);

    // find the best depth plane index for the current pixel
    // the best depth plane has the best similarity value
    // - best possible similarity value is 0
    // - worst possible similarity value is 254
    // - invalid similarity value is 255
    float bestSim = 255.f;
    int bestZIdx = -1;

    for(unsigned int vz = kernelArgs.depthRange.begin; vz < kernelArgs.depthRange.end; ++vz)
    {
      const float simAtZ = *get3DBufferAtConstant(in_volSim_d, kernelArgs.in_volSim_s, kernelArgs.in_volSim_p, vx, vy, vz);

      if(simAtZ < bestSim)
      {
        bestSim = simAtZ;
        bestZIdx = vz;
      }
    }

    // filtering out invalid values and values with a too bad score (above the user maximum similarity threshold)
    // note: this helps to reduce following calculations and also the storage volume of the depth maps.
    if((bestZIdx == -1) || (bestSim > kernelArgs.maxSimilarity))
    {
        out_bestDepthThicknessPtr.x = -1.f; // invalid depth
        out_bestDepthThicknessPtr.y = -1.f; // invalid thickness

        return;
    }

    // find best depth plane previous and next indexes
    const int bestZIdx_m1 = max(0, bestZIdx - 1);           // best depth plane previous index
    const int bestZIdx_p1 = min(kernelArgs.volDimZ - 1, bestZIdx + 1); // best depth plane next index

    // get best best depth current, previous and next plane depth values
    // note: float3 struct is useful for depth interpolation
    float3 depthPlanes;
    depthPlanes.x = BufPtrConstant<float>(in_depths_d, kernelArgs.in_depths_p).at(bestZIdx_m1, 0);  // best depth previous plane
    depthPlanes.y = BufPtrConstant<float>(in_depths_d, kernelArgs.in_depths_p).at(bestZIdx, 0);     // best depth plane
    depthPlanes.z = BufPtrConstant<float>(in_depths_d, kernelArgs.in_depths_p).at(bestZIdx_p1, 0);  // best depth next plane

    const float bestDepth    = depthPlaneToDepth(rcDeviceCamParams, depthPlanes.y, pix); // best depth
    const float bestDepth_m1 = depthPlaneToDepth(rcDeviceCamParams, depthPlanes.x, pix); // previous best depth
    const float bestDepth_p1 = depthPlaneToDepth(rcDeviceCamParams, depthPlanes.z, pix); // next best depth

#ifdef ALICEVISION_DEPTHMAP_RETRIEVE_BEST_Z_INTERPOLATION
    // with depth/sim interpolation
    // note: disable by default

    float3 sims;
    sims.x = *get3DBufferAtConstant(in_volSim_d, kernelArgs.in_volSim_s, kernelArgs.in_volSim_p, vx, vy, bestZIdx_m1);
    sims.y = bestSim;
    sims.z = *get3DBufferAtConstant(in_volSim_d, kernelArgs.in_volSim_s, kernelArgs.in_volSim_p, vx, vy, bestZIdx_p1);

    // convert sims from (0, 255) to (-1, +1)
    sims.x = (sims.x / 255.0f) * 2.0f - 1.0f;
    sims.y = (sims.y / 255.0f) * 2.0f - 1.0f;
    sims.z = (sims.z / 255.0f) * 2.0f - 1.0f;

    // interpolation between the 3 depth planes candidates
    const float refinedDepthPlane = refineDepthSubPixel(depthPlanes, sims);

    const float out_bestDepth = depthPlaneToDepth(rcDeviceCamParams, refinedDepthPlane, pix);
#else
    // without depth interpolation
    const float out_bestDepth = bestDepth;
#endif

    // compute output best depth thickness
    // thickness is the maximum distance between output best depth and previous or next depth
    // thickness can be inflate with thicknessMultFactor
    const float out_bestDepthThickness = max(bestDepth_p1 - out_bestDepth, out_bestDepth - bestDepth_m1) * kernelArgs.thicknessMultFactor;

    // write output depth/thickness
    out_bestDepthThicknessPtr.x = out_bestDepth;
    out_bestDepthThicknessPtr.y = out_bestDepthThickness;
}

[[kernel]] void
kernel_volumeRefineSimilarity_SgmNormalMap(device TSimRefine* inout_volSim_d [[buffer(0)]],
                                           constant const float2* in_sgmDepthPixSizeMap_d [[buffer(1)]],
                                           constant const float3* in_sgmNormalMap_d [[buffer(2)]],
                                           const texture2d<MTLRGBABaseType, access::sample> rcMipmapImage_tex [[texture(0)]],
                                           const texture2d<MTLRGBABaseType, access::sample> tcMipmapImage_tex [[texture(1)]],
                                           constant const DeviceCameraParams* constantCameraParametersArray_d[[buffer(28)]],
                                           constant const DevicePatchPattern& constantPatchPattern_d [[buffer(29)]],    // Extra DevicePatchPattern as push constant
                                           constant const ArgsVolumeRefineSimilarity_SgmNormalMap& kernelArgs [[buffer(30)]],
                                           const uint3 gid [[thread_position_in_grid]],
                                           const uint3 blockIdx [[threadgroup_position_in_grid]])
{
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;
    const unsigned int roiZ = blockIdx.z;

    /* Make available */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height()) // no need to check roiZ
        return;

    // R and T camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];
    constant const DeviceCameraParams& tcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.tcDeviceCameraParamsId];

    // corresponding volume and depth/sim map coordinates
    const unsigned int vx = roiX;
    const unsigned int vy = roiY;
    const unsigned int vz = kernelArgs.depthRange.begin + roiZ;

    // corresponding image coordinates
    const float x = float(kernelArgs.roi.x.begin + vx) * float(kernelArgs.stepXY);
    const float y = float(kernelArgs.roi.y.begin + vy) * float(kernelArgs.stepXY);

    // corresponding input sgm depth/pixSize (middle depth)
    const float2 in_sgmDepthPixSize = BufPtrConstant<float2>(in_sgmDepthPixSizeMap_d, kernelArgs.in_sgmDepthPixSizeMap_p).at(vx, vy);

    // sgm depth (middle depth) invalid or masked
    if(in_sgmDepthPixSize.x <= 0.0f)
        return;

    // initialize rc 3d point at sgm depth (middle depth)
    float3 p = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, float2(x, y), in_sgmDepthPixSize.x);

    // compute relative depth index offset from z center
    const int relativeDepthIndexOffset = vz - ((kernelArgs.volDimZ - 1) / 2);

    if(relativeDepthIndexOffset != 0)
    {
        // not z center
        // move rc 3d point by relative depth index offset * sgm pixSize
        const float pixSizeOffset = relativeDepthIndexOffset * in_sgmDepthPixSize.y; // input sgm pixSize
        move3DPointByRcPixSize(p, rcDeviceCamParams, pixSizeOffset);
    }

    // compute patch
    Patch patch;
    patch.p = p;
    patch.d = computePixSize(rcDeviceCamParams, p);

    // computeRotCSEpip
    {
      // vector from the reference camera to the 3d point
      float3 v1 = rcDeviceCamParams.C - patch.p;
      // vector from the target camera to the 3d point
      float3 v2 = tcDeviceCamParams.C - patch.p;
      av_normalize(v1);
      av_normalize(v2);

      // y has to be orthogonal to the epipolar plane
      // n has to be on the epipolar plane
      // x has to be on the epipolar plane

      patch.y = av_cross(v1, v2);
      av_normalize(patch.y);


      patch.n = BufPtrConstant<float3>(in_sgmNormalMap_d, kernelArgs.in_sgmNormalMap_p).at(vx, vy);

      patch.x = av_cross(patch.y, patch.n);
      av_normalize(patch.x);
    }

    // we need positive and filtered similarity values
    constexpr bool invertAndFilter = true;

    float fsimInvertedFiltered = MAXFLOAT;

    // compute similarity
    if(kernelArgs.useCustomPatchPattern)
    {
        fsimInvertedFiltered = compNCCby3DptsYK_customPatchPattern<invertAndFilter>(rcDeviceCamParams,
                                                                                    tcDeviceCamParams,
                                                                                    rcMipmapImage_tex,
                                                                                    tcMipmapImage_tex,
                                                                                    kernelArgs.rcRefineLevelWidth,
                                                                                    kernelArgs.rcRefineLevelHeight,
                                                                                    kernelArgs.tcRefineLevelWidth,
                                                                                    kernelArgs.tcRefineLevelHeight,
                                                                                    kernelArgs.rcMipmapLevel,
                                                                                    kernelArgs.invGammaC,
                                                                                    kernelArgs.invGammaP,
                                                                                    kernelArgs.useConsistentScale,
                                                                                    patch,
                                                                                    constantPatchPattern_d);
    }
    else
    {
        fsimInvertedFiltered = compNCCby3DptsYK<invertAndFilter>(rcDeviceCamParams,
                                                                 tcDeviceCamParams,
                                                                 rcMipmapImage_tex,
                                                                 tcMipmapImage_tex,
                                                                 kernelArgs.rcRefineLevelWidth,
                                                                 kernelArgs.rcRefineLevelHeight,
                                                                 kernelArgs.tcRefineLevelWidth,
                                                                 kernelArgs.tcRefineLevelHeight,
                                                                 kernelArgs.rcMipmapLevel,
                                                                 kernelArgs.wsh,
                                                                 kernelArgs.invGammaC,
                                                                 kernelArgs.invGammaP,
                                                                 kernelArgs.useConsistentScale,
                                                                 patch);
    }

    if(fsimInvertedFiltered == MAXFLOAT) // invalid similarity
    {
        // do nothing
        return;
    }

    // get output similarity pointer
    device TSimRefine* outSimPtr = get3DBufferAtDevice(inout_volSim_d, kernelArgs.inout_volSim_s, kernelArgs.inout_volSim_p, vx, vy, vz);

    // add the output similarity value
#ifdef TSIM_REFINE_USE_HALF
    //*outSimPtr = (*outSimPtr) + TSimRefine(fsimInvertedFiltered);
    //*outSimPtr = (*outSimPtr) + half(fsimInvertedFiltered);
    *outSimPtr = half(float(*outSimPtr) + fsimInvertedFiltered); // perform the addition in float
#else
    *outSimPtr += TSimRefine(fsimInvertedFiltered);
#endif
}

[[kernel]] void
kernel_volumeRefineSimilarity_NoSgmNormalMap(device TSimRefine* inout_volSim_d [[buffer(0)]],
                                             constant const float2* in_sgmDepthPixSizeMap_d [[buffer(1)]],
                                             const texture2d<MTLRGBABaseType, access::sample> rcMipmapImage_tex [[texture(0)]],
                                             const texture2d<MTLRGBABaseType, access::sample> tcMipmapImage_tex [[texture(1)]],
                                             constant const DeviceCameraParams* constantCameraParametersArray_d[[buffer(28)]],
                                             constant const DevicePatchPattern& constantPatchPattern_d [[buffer(29)]],    // Extra DevicePatchPattern as push constant
                                             constant const ArgsVolumeRefineSimilarity_NoSgmNormalMap& kernelArgs [[buffer(30)]],
                                             const uint3 gid [[thread_position_in_grid]],
                                             const uint3 blockIdx [[threadgroup_position_in_grid]])
{
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;
    const unsigned int roiZ = blockIdx.z;

    /* Make available */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height()) // no need to check roiZ
        return;

    // R and T camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];
    constant const DeviceCameraParams& tcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.tcDeviceCameraParamsId];

    // corresponding volume and depth/sim map coordinates
    const unsigned int vx = roiX;
    const unsigned int vy = roiY;
    const unsigned int vz = kernelArgs.depthRange.begin + roiZ;

    // corresponding image coordinates
    const float x = float(kernelArgs.roi.x.begin + vx) * float(kernelArgs.stepXY);
    const float y = float(kernelArgs.roi.y.begin + vy) * float(kernelArgs.stepXY);

    // corresponding input sgm depth/pixSize (middle depth)
    const float2 in_sgmDepthPixSize = BufPtrConstant<float2>(in_sgmDepthPixSizeMap_d, kernelArgs.in_sgmDepthPixSizeMap_p).at(vx, vy);

    // sgm depth (middle depth) invalid or masked
    if(in_sgmDepthPixSize.x <= 0.0f)
        return;

    // initialize rc 3d point at sgm depth (middle depth)
    float3 p = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, float2(x, y), in_sgmDepthPixSize.x);

    // compute relative depth index offset from z center
    const int relativeDepthIndexOffset = vz - ((kernelArgs.volDimZ - 1) / 2);

    if(relativeDepthIndexOffset != 0)
    {
        // not z center
        // move rc 3d point by relative depth index offset * sgm pixSize
        const float pixSizeOffset = relativeDepthIndexOffset * in_sgmDepthPixSize.y; // input sgm pixSize
        move3DPointByRcPixSize(p, rcDeviceCamParams, pixSizeOffset);
    }

    // compute patch
    Patch patch;
    patch.p = p;
    patch.d = computePixSize(rcDeviceCamParams, p);

    // computeRotCSEpip
    {
      // vector from the reference camera to the 3d point
      float3 v1 = rcDeviceCamParams.C - patch.p;
      // vector from the target camera to the 3d point
      float3 v2 = tcDeviceCamParams.C - patch.p;
      av_normalize(v1);
      av_normalize(v2);

      // y has to be orthogonal to the epipolar plane
      // n has to be on the epipolar plane
      // x has to be on the epipolar plane

      patch.y = av_cross(v1, v2);
      av_normalize(patch.y);

      patch.n = (v1 + v2) / 2.0f;
      av_normalize(patch.n);

      patch.x = av_cross(patch.y, patch.n);
      av_normalize(patch.x);
    }

    // we need positive and filtered similarity values
    constexpr bool invertAndFilter = true;

    float fsimInvertedFiltered = MAXFLOAT;

    // compute similarity
    if(kernelArgs.useCustomPatchPattern)
    {
        fsimInvertedFiltered = compNCCby3DptsYK_customPatchPattern<invertAndFilter>(rcDeviceCamParams,
                                                                                    tcDeviceCamParams,
                                                                                    rcMipmapImage_tex,
                                                                                    tcMipmapImage_tex,
                                                                                    kernelArgs.rcRefineLevelWidth,
                                                                                    kernelArgs.rcRefineLevelHeight,
                                                                                    kernelArgs.tcRefineLevelWidth,
                                                                                    kernelArgs.tcRefineLevelHeight,
                                                                                    kernelArgs.rcMipmapLevel,
                                                                                    kernelArgs.invGammaC,
                                                                                    kernelArgs.invGammaP,
                                                                                    kernelArgs.useConsistentScale,
                                                                                    patch,
                                                                                    constantPatchPattern_d);
    }
    else
    {
        fsimInvertedFiltered = compNCCby3DptsYK<invertAndFilter>(rcDeviceCamParams,
                                                                 tcDeviceCamParams,
                                                                 rcMipmapImage_tex,
                                                                 tcMipmapImage_tex,
                                                                 kernelArgs.rcRefineLevelWidth,
                                                                 kernelArgs.rcRefineLevelHeight,
                                                                 kernelArgs.tcRefineLevelWidth,
                                                                 kernelArgs.tcRefineLevelHeight,
                                                                 kernelArgs.rcMipmapLevel,
                                                                 kernelArgs.wsh,
                                                                 kernelArgs.invGammaC,
                                                                 kernelArgs.invGammaP,
                                                                 kernelArgs.useConsistentScale,
                                                                 patch);
    }

    if(fsimInvertedFiltered == MAXFLOAT) // invalid similarity
    {
        // do nothing
        return;
    }

    // get output similarity pointer
    device TSimRefine* outSimPtr = get3DBufferAtDevice(inout_volSim_d, kernelArgs.inout_volSim_s, kernelArgs.inout_volSim_p, vx, vy, vz);

    // add the output similarity value
#ifdef TSIM_REFINE_USE_HALF
    //*outSimPtr = (*outSimPtr) + TSimRefine(fsimInvertedFiltered);
    //*outSimPtr = (*outSimPtr) + half(fsimInvertedFiltered);
    *outSimPtr = half(float(*outSimPtr) + fsimInvertedFiltered); // perform the addition in float
#else
    *outSimPtr += TSimRefine(fsimInvertedFiltered);
#endif
}

[[kernel]] void
kernel_volumeRefineBestDepth(device float2* out_refineDepthSimMap_d [[buffer(0)]],
                             constant const float2* in_sgmDepthPixSizeMap_d [[buffer(1)]],
                             constant const TSimRefine* in_volSim_d [[buffer(2)]],
                             constant const ArgsVolumeRefineBestDepth& kernelArgs [[buffer(30)]],
                             const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int vx = gid.x;
    const unsigned int vy = gid.y;

    /* Make available */
    const auto roi = kernelArgs.roi;

    if(vx >= roi.width() || vy >= roi.height())
        return;

    // corresponding input sgm depth/pixSize (middle depth)
    const float2 in_sgmDepthPixSize = BufPtrConstant<float2>(in_sgmDepthPixSizeMap_d, kernelArgs.in_sgmDepthPixSizeMap_p).at(vx, vy);

    // corresponding output depth/sim pointer
    device float2& out_bestDepthSimPtr = BufPtrDevice<float2>(out_refineDepthSimMap_d, kernelArgs.out_refineDepthSimMap_p).at(vx, vy);

    // sgm depth (middle depth) invalid or masked
    if(in_sgmDepthPixSize.x <= 0.0f)
    {
        out_bestDepthSimPtr.x = in_sgmDepthPixSize.x;  // -1 (invalid) or -2 (masked)
        out_bestDepthSimPtr.y = 1.0f;                  // similarity between (-1, +1)
        return;
    }

    // find best z sample per pixel
    float bestSampleSim = 0.f;      // all sample sim <= 0.f
    int bestSampleOffsetIndex = 0;  // default is middle depth (SGM)

    // sliding gaussian window
    for(int sample = -kernelArgs.halfNbSamples; sample <= kernelArgs.halfNbSamples; ++sample)
    {
        float sampleSim = 0.f;

        for(int vz = 0; vz < kernelArgs.volDimZ; ++vz)
        {
            const int rz = (vz - kernelArgs.halfNbDepths);    // relative depth index offset
            const int zs = rz * kernelArgs.samplesPerPixSize; // relative sample offset

            // get the inverted similarity sum value
            // best value is the HIGHEST
            // worst value is 0
            const float invSimSum = *get3DBufferAtConstant(in_volSim_d, kernelArgs.in_volSim_s, kernelArgs.in_volSim_p, vx, vy, vz);

            // reverse the inverted similarity sum value
            // best value is the LOWEST
            // worst value is 0
            const float simSum = -invSimSum;

            // apply gaussian
            // see: https://www.desmos.com/calculator/ribalnoawq
            sampleSim += simSum * exp(-((zs - sample) * (zs - sample)) / kernelArgs.twoTimesSigmaPowerTwo);
        }

        if(sampleSim < bestSampleSim)
        {
            bestSampleOffsetIndex = sample;
            bestSampleSim = sampleSim;
        }
    }

    // compute sample size
    const float sampleSize = in_sgmDepthPixSize.y / kernelArgs.samplesPerPixSize; // input sgm pixSize / samplesPerPixSize

    // compute sample size offset from z center
    const float sampleSizeOffset = bestSampleOffsetIndex * sampleSize;

    // compute best depth
    // input sgm depth (middle depth) + sample size offset from z center
    const float bestDepth = in_sgmDepthPixSize.x + sampleSizeOffset;

    // write output best depth/sim
    out_bestDepthSimPtr.x = bestDepth;
    out_bestDepthSimPtr.y = bestSampleSim;
}

ALICEVISION_DEPTHMAP_MTL_NS_END
