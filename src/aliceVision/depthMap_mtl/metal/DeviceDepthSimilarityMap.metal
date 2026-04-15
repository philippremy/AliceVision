// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Namespace.hpp>

#include <aliceVision/depthMap_mtl/private/DeviceCameraParams.hpp>
#include <aliceVision/depthMap_mtl/private/KernelArgs.hpp>

/* Metal Headers */
#include <aliceVision/depthMap_mtl/metal/Buffer.hpp>
#include <aliceVision/depthMap_mtl/metal/Eig33.hpp>
#include <aliceVision/depthMap_mtl/metal/Math.hpp>
#include <aliceVision/depthMap_mtl/metal/Matrix.hpp>
#include <aliceVision/depthMap_mtl/metal/Patch.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

/* TWsh is usually templated, currently with the value 3 */
constant constexpr const int TWsh = 3;

// SAMPLER FOR MTLBuffers: Non-normalized and nearest neighbor
constexpr const sampler TEX_SAMPLER_NONORM_NEAREST(coord::pixel,
                                                   address::clamp_to_edge,
                                                   filter::nearest);

inline float
orientedPointPlaneDistanceNormalizedNormal(thread const float3& point,
                                           thread const float3& planePoint,
                                           thread const float3& planeNormalNormalized)
{
    return (dot(point, planeNormalNormalized) - dot(planePoint, planeNormalNormalized));
}

/**
 * @return (smoothStep, energy)
 */
inline float2
getCellSmoothStepEnergy(constant const DeviceCameraParams& rcDeviceCamParams,
                        thread const texture2d<float, access::sample>& in_depth_tex,
                        thread const float2& cell0,
                        thread const float2& offsetRoi)
{
    float2 out = float2(0.0f, 180.0f);

    // get pixel depth from the depth texture
    // note: we do not use 0.5f offset because in_depth_tex use nearest neighbor interpolation
    const float d0 = in_depth_tex.sample(TEX_SAMPLER_NONORM_NEAREST, cell0).x;

    // early exit: depth is <= 0
    if(d0 <= 0.0f)
        return out;

    // consider the neighbor pixels
    const float2 cellL = cell0 + float2( 0.f, -1.f); // Left
    const float2 cellR = cell0 + float2( 0.f,  1.f); // Right
    const float2 cellU = cell0 + float2(-1.f,  0.f); // Up
    const float2 cellB = cell0 + float2( 1.f,  0.f); // Bottom

    // get associated depths from depth texture
    // note: we do not use 0.5f offset because in_depth_tex use nearest neighbor interpolation
    const float dL = in_depth_tex.sample(TEX_SAMPLER_NONORM_NEAREST, cellL).x;
    const float dR = in_depth_tex.sample(TEX_SAMPLER_NONORM_NEAREST, cellR).x;
    const float dU = in_depth_tex.sample(TEX_SAMPLER_NONORM_NEAREST, cellU).x;
    const float dB = in_depth_tex.sample(TEX_SAMPLER_NONORM_NEAREST, cellB).x;

    // get associated 3D points
    const float3 p0 = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, cell0 + offsetRoi, d0);
    const float3 pL = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, cellL + offsetRoi, dL);
    const float3 pR = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, cellR + offsetRoi, dR);
    const float3 pU = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, cellU + offsetRoi, dU);
    const float3 pB = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, cellB + offsetRoi, dB);

    // compute the average point based on neighbors (cg)
    float3 cg = float3(0.0f, 0.0f, 0.0f);
    float n = 0.0f;

    if(dL > 0.0f) { cg = cg + pL; n++; }
    if(dR > 0.0f) { cg = cg + pR; n++; }
    if(dU > 0.0f) { cg = cg + pU; n++; }
    if(dB > 0.0f) { cg = cg + pB; n++; }

    // if we have at least one valid depth
    if(n > 1.0f)
    {
        cg = cg / n; // average of x, y, depth
        float3 vcn = rcDeviceCamParams.C - p0;
        av_normalize(vcn);
        // pS: projection of cg on the line from p0 to camera
        const float3 pS = closestPointToLine3D(cg, p0, vcn);
        // keep the depth difference between pS and p0 as the smoothing step
        out.x = av_size(rcDeviceCamParams.C - pS) - d0;
    }

    float e = 0.0f;
    n = 0.0f;

    if(dL > 0.0f && dR > 0.0f)
    {
        // large angle between neighbors == flat area => low energy
        // small angle between neighbors == non-flat area => high energy
        e = max(e, (180.0f - angleBetwABandAC(p0, pL, pR)));
        n++;
    }
    if(dU > 0.0f && dB > 0.0f)
    {
        e = max(e, (180.0f - angleBetwABandAC(p0, pU, pB)));
        n++;
    }
    // the higher the energy, the less flat the area
    if(n > 0.0f)
        out.y = e;

    return out;
}

[[kernel]] void
kernel_depthSimMapComputeNormal(device float3* out_normalMap_d [[buffer(0)]],
                                constant const float2* in_depthSimMap_d [[buffer(1)]],
                                constant const DeviceCameraParams* constantCameraParametersArray_d [[buffer(29)]], // Extra DeviceCameraParams as push constant
                                constant const ArgsDepthSimMapComputeNormal& kernelArgs [[buffer(30)]],
                                const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height())
        return;

    // R camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];

    // corresponding image coordinates
    const unsigned int x = (roi.x.begin + roiX) * (unsigned int)(kernelArgs.stepXY);
    const unsigned int y = (roi.y.begin + roiY) * (unsigned int)(kernelArgs.stepXY);

    // corresponding input depth
    const float in_depth = BufPtrConstant<float2>(in_depthSimMap_d, kernelArgs.in_depthSimMap_p).at(roiX, roiY).x; // use only depth

    // corresponding output normal
    device float3& out_normal = BufPtrDevice<float3>(out_normalMap_d, kernelArgs.out_normalMap_p).at(roiX, roiY);

    // no depth
    if(in_depth <= 0.0f)
    {
        out_normal = float3(-1.f, -1.f, -1.f);
        return;
    }

    const float3 p = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, float2(float(x), float(y)), in_depth);
    const float pixSize = av_size(p - get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, float2(float(x + 1), float(y)), in_depth));

    mtl_stat3d s3d = mtl_stat3d();

    #pragma unroll
    for(int yp = -TWsh; yp <= TWsh; ++yp)
    {
        const int roiYp = int(roiY) + yp;
        if(roiYp < 0)
            continue;

        #pragma unroll
        for(int xp = -TWsh; xp <= TWsh; ++xp)
        {
            const int roiXp = int(roiX) + xp;
            if(roiXp < 0)
                continue;

            const float depthP = BufPtrConstant<float2>(in_depthSimMap_d, kernelArgs.in_depthSimMap_p).at(roiXp, roiYp).x;  // use only depth

            if((depthP > 0.0f) && (fabs(depthP - in_depth) < 30.0f * pixSize))
            {
                const float w = 1.0f;
                const float2 pixP = float2(float(int(x) + xp), float(int(y) + yp));
                const float3 pP = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, pixP, depthP);
                s3d.update(pP, w);
            }
        }
    }

    float3 pp = p;
    float3 nn = float3(-1.f, -1.f, -1.f);

    if(!s3d.computePlaneByPCA(pp, nn))
    {
        out_normal = float3(-1.f, -1.f, -1.f);
        return;
    }

    float3 nc = rcDeviceCamParams.C - p;
    av_normalize(nc);

    if(orientedPointPlaneDistanceNormalizedNormal(pp + nn, pp, nc) < 0.0f)
    {
        nn.x = -nn.x;
        nn.y = -nn.y;
        nn.z = -nn.z;
    }

    out_normal = nn;
}

[[kernel]] void
kernel_depthThicknessSmoothThickness(device float2* inout_depthThicknessMap_d [[buffer(0)]],
                                     constant const ArgsDepthThicknessSmoothThickness& kernelArgs [[buffer(30)]],
                                     uint3 gid [[thread_position_in_grid]])
{
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height())
        return;

    // corresponding output depth/thickness (depth unchanged)
    device float2& inout_depthThickness = BufPtrDevice<float2>(inout_depthThicknessMap_d, kernelArgs.inout_depthThicknessMap_p).at(roiX, roiY);

    // depth invalid or masked
    if(inout_depthThickness.x <= 0.0f)
        return;

    const float minThickness = kernelArgs.minThicknessInflate * inout_depthThickness.y;
    const float maxThickness = kernelArgs.maxThicknessInflate * inout_depthThickness.y;

    // compute average depth distance to the center pixel
    float sumCenterDepthDist = 0.f;
    int nbValidPatchPixels = 0;

    // patch 3x3
    for(int yp = -1; yp <= 1; ++yp)
    {
        for(int xp = -1; xp <= 1; ++xp)
        {
            // compute patch coordinates
            const unsigned int roiXp = uint(roiX) + xp;
            const unsigned int roiYp = uint(roiY) + yp;

            if((xp == 0 && yp == 0) ||                // avoid pixel center
               roiXp < 0 || roiXp >= roi.width() ||   // avoid pixel outside the ROI
               roiYp < 0 || roiYp >= roi.height())    // avoid pixel outside the ROI
            {
                continue;
            }

            // corresponding path depth/thickness
            device const float2& in_depthThicknessPatch = BufPtrDevice<float2>(inout_depthThicknessMap_d, kernelArgs.inout_depthThicknessMap_p).at(roiXp, roiYp);

            // patch depth valid
            if(in_depthThicknessPatch.x > 0.0f)
            {
                const float depthDistance = abs(inout_depthThickness.x - in_depthThicknessPatch.x);
                sumCenterDepthDist += max(minThickness, min(maxThickness, depthDistance)); // clamp (minThickness, maxThickness)
                ++nbValidPatchPixels;
            }
        }
    }

    // we require at least 3 valid patch pixels (over 8)
    if(nbValidPatchPixels < 3)
        return;

    // write output smooth thickness
    inout_depthThickness.y = sumCenterDepthDist / nbValidPatchPixels;
}

[[kernel]] void
kernel_computeSgmUpscaledDepthPixSizeMap_Bilinear(device float2* out_upscaledDepthPixSizeMap_d [[buffer(0)]],
                                                  constant const float2* in_sgmDepthThicknessMap_d [[buffer(1)]],
                                                  const texture2d<MTLRGBABaseType, access::sample> rcMipmapImage_tex [[texture(0)]],
                                                  constant const DeviceCameraParams* constantCameraParametersArray_d [[buffer(29)]],
                                                  constant const ArgsComputeSgmUpscaledDepthPixSizeMap_Bilinear&  kernelArgs [[buffer(30)]],
                                                  const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height())
        return;

    // corresponding image coordinates
    const unsigned int x = (roi.x.begin + roiX) * (unsigned int)(kernelArgs.stepXY);
    const unsigned int y = (roi.y.begin + roiY) * (unsigned int)(kernelArgs.stepXY);

    // corresponding output upscaled depth/pixSize map
    device float2& out_depthPixSize = BufPtrDevice<float2>(out_upscaledDepthPixSizeMap_d, kernelArgs.out_upscaledDepthPixSizeMap_p).at(roiX, roiY);

    // filter masked pixels with alpha
    if(rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((float(x) + 0.5f) / float(kernelArgs.rcLevelWidth), (float(y) + 0.5f) / float(kernelArgs.rcLevelHeight)), kernelArgs.rcMipmapLevel).w < ALICEVISION_DEPTHMAP_RC_MIN_ALPHA)
    {
        out_depthPixSize = float2(-2.f, 0.f);
        return;
    }

    // find adjacent pixels
    const float oy = (float(roiY) - 0.5f) * kernelArgs.ratio;
    const float ox = (float(roiX) - 0.5f) * kernelArgs.ratio;

    int xp = floor(ox);
    int yp = floor(oy);

    xp = min(xp, int(roi.width()  * kernelArgs.ratio) - 2);
    yp = min(yp, int(roi.height() * kernelArgs.ratio) - 2);

    const float2 lu = BufPtrConstant<float2>(in_sgmDepthThicknessMap_d, kernelArgs.in_sgmDepthThicknessMap_p).at(xp, yp);
    const float2 ru = BufPtrConstant<float2>(in_sgmDepthThicknessMap_d, kernelArgs.in_sgmDepthThicknessMap_p).at(xp + 1, yp);
    const float2 rd = BufPtrConstant<float2>(in_sgmDepthThicknessMap_d, kernelArgs.in_sgmDepthThicknessMap_p).at(xp + 1, yp + 1);
    const float2 ld = BufPtrConstant<float2>(in_sgmDepthThicknessMap_d, kernelArgs.in_sgmDepthThicknessMap_p).at(xp, yp + 1);

    // find corresponding depth/thickness
    float2 out_depthThickness;

    if(lu.x <= 0.0f || ru.x <= 0.0f || rd.x <= 0.0f || ld.x <= 0.0f)
    {
        // at least one corner depth is invalid
        // average the other corners to get a proper depth/thickness
        float2 sumDepthThickness = {0.0f, 0.0f};
        int count = 0;

        if(lu.x > 0.0f)
        {
            sumDepthThickness = sumDepthThickness + lu;
            ++count;
        }
        if(ru.x > 0.0f)
        {
            sumDepthThickness = sumDepthThickness + ru;
            ++count;
        }
        if(rd.x > 0.0f)
        {
            sumDepthThickness = sumDepthThickness + rd;
            ++count;
        }
        if(ld.x > 0.0f)
        {
            sumDepthThickness = sumDepthThickness + ld;
            ++count;
        }
        if(count != 0)
        {
            out_depthThickness = {sumDepthThickness.x / float(count), sumDepthThickness.y / float(count)};
        }
        else
        {
            // invalid depth
            out_depthPixSize = {-1.0f, 1.0f};
            return;
        }
    }
    else
    {
        // bilinear interpolation
        const float ui = ox - float(xp);
        const float vi = oy - float(yp);
        const float2 u = lu + (ru - lu) * ui;
        const float2 d = ld + (rd - ld) * ui;
        out_depthThickness = u + (d - u) * vi;
    }

#ifdef ALICEVISION_DEPTHMAP_COMPUTE_PIXSIZEMAP
    // R camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];

    // get rc 3d point
    const float3 p = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, float2(float(x), float(y)), out_depthThickness.x);

    // compute and write rc 3d point pixSize
    const float out_pixSize = computePixSize(rcDeviceCamParams, p);
#else
    // compute pixSize from depth thickness
    const float out_pixSize = out_depthThickness.y / kernelArgs.halfNbDepths;
#endif

    // write output depth/pixSize
    out_depthPixSize.x = out_depthThickness.x;
    out_depthPixSize.y = out_pixSize;
}

[[kernel]] void
kernel_computeSgmUpscaledDepthPixSizeMap_NearestNeighbor(device float2* out_upscaledDepthPixSizeMap_d [[buffer(0)]],
                                                         constant const float2* in_sgmDepthThicknessMap_d [[buffer(1)]],
                                                         const texture2d<MTLRGBABaseType, access::sample> rcMipmapImage_tex,
                                                         constant const DeviceCameraParams* constantCameraParametersArray_d [[buffer(29)]],
                                                         constant const ArgsComputeSgmUpscaledDepthPixSizeMap_NearestNeighbor&  kernelArgs [[buffer(30)]],
                                                         const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height())
        return;

    // corresponding image coordinates
    const unsigned int x = (roi.x.begin + roiX) * (unsigned int)(kernelArgs.stepXY);
    const unsigned int y = (roi.y.begin + roiY) * (unsigned int)(kernelArgs.stepXY);

    // corresponding output upscaled depth/pixSize map
    device float2& out_depthPixSize = BufPtrDevice<float2>(out_upscaledDepthPixSizeMap_d, kernelArgs.out_upscaledDepthPixSizeMap_p).at(roiX, roiY);

    // filter masked pixels (alpha < 0.9f)
    if(rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((float(x) + 0.5f) / float(kernelArgs.rcLevelWidth), (float(y) + 0.5f) / float(kernelArgs.rcLevelHeight)), kernelArgs.rcMipmapLevel).w < 0.9f)
    {
        out_depthPixSize = float2(-2.f, 0.f);
        return;
    }

    // find corresponding depth/thickness
    // nearest neighbor, no interpolation
    const float oy = (float(roiY) - 0.5f) * kernelArgs.ratio;
    const float ox = (float(roiX) - 0.5f) * kernelArgs.ratio;

    int xp = floor(ox + 0.5);
    int yp = floor(oy + 0.5);

    xp = min(xp, int(roi.width()  * kernelArgs.ratio) - 1);
    yp = min(yp, int(roi.height() * kernelArgs.ratio) - 1);

    const float2 out_depthThickness = BufPtrConstant<float2>(in_sgmDepthThicknessMap_d, kernelArgs.in_sgmDepthThicknessMap_p).at(xp, yp);

#ifdef ALICEVISION_DEPTHMAP_COMPUTE_PIXSIZEMAP
    // R camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];

    // get rc 3d point
    const float3 p = get3DPointForPixelAndDepthFromRC(rcDeviceCamParams, float2(float(x), float(y)), out_depthThickness.x);

    // compute and write rc 3d point pixSize
    const float out_pixSize = computePixSize(rcDeviceCamParams, p);
#else
    // compute pixSize from depth thickness
    const float out_pixSize = out_depthThickness.y / kernelArgs.halfNbDepths;
#endif

    // write output depth/pixSize
    out_depthPixSize.x = out_depthThickness.x;
    out_depthPixSize.y = out_pixSize;
}

[[kernel]] void
kernel_mapUpscale_float3(device float3* out_upscaledMap_d [[buffer(0)]],
                         constant const float3* in_map_d [[buffer(1)]],
                         constant const ArgsMapUpscale_float3& kernelArgs [[buffer(30)]],
                         const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int x = gid.x;
    const unsigned int y = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(x >= roi.width() || y >= roi.height())
        return;

    const float ox = (float(x) - 0.5f) * kernelArgs.ratio;
    const float oy = (float(y) - 0.5f) * kernelArgs.ratio;

    // nearest neighbor, no interpolation
    const int xp = min(int(floor(ox + 0.5)), int(roi.width()  * kernelArgs.ratio) - 1);
    const int yp = min(int(floor(oy + 0.5)), int(roi.height() * kernelArgs.ratio) - 1);

    // write output upscaled map
    BufPtrDevice<float3>(out_upscaledMap_d, kernelArgs.out_upscaledMap_p).at(x, y) = BufPtrConstant<float3>(in_map_d, kernelArgs.in_map_p).at(xp, yp);
}

[[kernel]] void
kernel_depthSimMapCopyDepthOnly(device float2* out_deptSimMap_d [[buffer(0)]],
                                constant const float2* in_depthSimMap_d [[buffer(1)]],
                                constant const ArgsDepthSimMapCopyDepthOnly& kernelArgs [[buffer(30)]],
                                const uint3 gid [[thread_position_in_grid]])
{
    const unsigned int x = gid.x;
    const unsigned int y = gid.y;

    if(x >= kernelArgs.width || y >= kernelArgs.height)
        return;

    // write output
    device float2& out_depthSim = BufPtrDevice<float2>(out_deptSimMap_d, kernelArgs.out_deptSimMap_p).at(x, y);
    out_depthSim.x = BufPtrConstant<float2>(in_depthSimMap_d, kernelArgs.in_depthSimMap_p).at(x, y).x;
    out_depthSim.y = kernelArgs.defaultSim;
}

[[kernel]] void
kernel_optimizeVarLofLABtoW(device float* out_varianceMap_d [[buffer(0)]],
                            const texture2d<MTLRGBABaseType, access::sample> rcMipmapImage_tex [[texture(0)]],
                            constant const ArgsOptimizeVarLofLABtoW& kernelArgs [[buffer(30)]],
                            const uint3 gid [[thread_position_in_grid]])
{
    // roi and varianceMap coordinates
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height())
        return;

    // corresponding image coordinates
    const float x = float(roi.x.begin + roiX) * float(kernelArgs.stepXY);
    const float y = float(roi.y.begin + roiY) * float(kernelArgs.stepXY);

    // compute inverse width / height
    // note: useful to compute p1 / m1 normalized coordinates
    const float invLevelWidth  = 1.f / float(kernelArgs.rcLevelWidth);
    const float invLevelHeight = 1.f / float(kernelArgs.rcLevelHeight);

    // compute gradient size of L
    // note: we use 0.5f offset because rcTex texture use interpolation
    const float xM1 = rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2(((x - 1.f) + 0.5f) * invLevelWidth, ((y + 0.f) + 0.5f) * invLevelHeight), kernelArgs.rcMipmapLevel).x;
    const float xP1 = rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2(((x + 1.f) + 0.5f) * invLevelWidth, ((y + 0.f) + 0.5f) * invLevelHeight), kernelArgs.rcMipmapLevel).x;
    const float yM1 = rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2(((x + 0.f) + 0.5f) * invLevelWidth, ((y - 1.f) + 0.5f) * invLevelHeight), kernelArgs.rcMipmapLevel).x;
    const float yP1 = rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2(((x + 0.f) + 0.5f) * invLevelWidth, ((y + 1.f) + 0.5f) * invLevelHeight), kernelArgs.rcMipmapLevel).x;

    const float2 g = float2(xM1 - xP1, yM1 - yP1); // TODO: not divided by 2?
    const float grad = av_size(g);

    // write output
    BufPtrDevice<float>(out_varianceMap_d, kernelArgs.out_varianceMap_p).at(roiX, roiY) = grad;
}


[[kernel]] void
kernel_optimizeGetOptDeptMapFromOptDepthSimMap(device float* out_tmpOptDepthMap_d [[buffer(0)]],
                                               constant const float2* in_optDepthSimMap_d [[buffer(1)]],
                                               constant const ArgsOptimizeGetOptDeptMapFromOptDepthSimMap& kernelArgs [[buffer(30)]],
                                               const uint3 gid [[thread_position_in_grid]])
{
    // roi and depth/sim map part coordinates
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height())
        return;

    BufPtrDevice<float>(out_tmpOptDepthMap_d, kernelArgs.out_tmpOptDepthMap_p).at(roiX, roiY) = BufPtrConstant<float2>(in_optDepthSimMap_d, kernelArgs.in_optDepthSimMap_p).at(roiX, roiY).x; // depth
}

[[kernel]] void
kernel_optimizeDepthSimMap(device float2* out_optimizeDepthSimMap_d [[buffer(0)]],
                           constant const float2* in_sgmDepthPixSizeMap_d [[buffer(1)]],
                           constant const float2* in_refineDepthSimMap_d [[buffer(2)]],
                           const texture2d<float, access::sample> imgVariance_tex [[texture(0)]],  // VIEWS INTO AN MTLBuffer, unnormalized ccordinates and nearest neighbor
                           const texture2d<float, access::sample> depth_tex  [[texture(1)]],        // VIEWS INTO AN MTLBuffer, unnormalized ccordinates and nearest neighbor
                           constant const DeviceCameraParams* constantCameraParametersArray_d [[buffer(29)]],
                           constant const ArgsOptimizeDepthSimMap& kernelArgs [[buffer(30)]],
                           const uint3 gid [[thread_position_in_grid]])
{
    // roi and imgVariance_tex, depth_tex coordinates
    const unsigned int roiX = gid.x;
    const unsigned int roiY = gid.y;

    /* Makes it available for calling */
    const auto roi = kernelArgs.roi;

    if(roiX >= roi.width() || roiY >= roi.height())
        return;

    // R camera parameters
    constant const DeviceCameraParams& rcDeviceCamParams = constantCameraParametersArray_d[kernelArgs.rcDeviceCameraParamsId];

    // SGM upscale (rough) depth/pixSize
    const float2 sgmDepthPixSize = BufPtrConstant<float2>(in_sgmDepthPixSizeMap_d, kernelArgs.in_sgmDepthPixSizeMap_p).at(roiX, roiY);
    const float sgmDepth = sgmDepthPixSize.x;
    const float sgmPixSize = sgmDepthPixSize.y;

    // refined and fused (fine) depth/sim
    const float2 refineDepthSim = BufPtrConstant<float2>(in_refineDepthSimMap_d, kernelArgs.in_refineDepthSimMap_p).at(roiX, roiY);
    const float refineDepth = refineDepthSim.x;
    const float refineSim = refineDepthSim.y;

    // output optimized depth/sim
    device float2& out_optDepthSimPtr = BufPtrDevice<float2>(out_optimizeDepthSimMap_d, kernelArgs.out_optimizeDepthSimMap_p).at(roiX, roiY);
    float2 out_optDepthSim = (kernelArgs.iter == 0) ? float2(sgmDepth, refineSim) : out_optDepthSimPtr;
    const float depthOpt = out_optDepthSim.x;

    if (depthOpt > 0.0f)
    {
        const float2 depthSmoothStepEnergy = getCellSmoothStepEnergy(rcDeviceCamParams, depth_tex, {float(roiX), float(roiY)}, {float(roi.x.begin), float(roi.y.begin)}); // (smoothStep, energy)
        float stepToSmoothDepth = depthSmoothStepEnergy.x;
        stepToSmoothDepth = copysign(min(abs(stepToSmoothDepth), sgmPixSize / 10.0f), stepToSmoothDepth);
        const float depthEnergy = depthSmoothStepEnergy.y; // max angle with neighbors
        float stepToFineDM = refineDepth - depthOpt; // distance to refined/noisy input depth map
        stepToFineDM = copysign(min(abs(stepToFineDM), sgmPixSize / 10.0f), stepToFineDM);

        const float stepToRoughDM = sgmDepth - depthOpt; // distance to smooth/robust input depth map
        const float imgColorVariance = imgVariance_tex.sample(TEX_SAMPLER_NONORM_NEAREST, float2(float(roiX), float(roiY))).x; // do not use 0.5f offset because imgVariance_tex use nearest neighbor interpolation
        const float colorVarianceThresholdForSmoothing = 20.0f;
        const float angleThresholdForSmoothing = 30.0f; // 30

        // https://www.desmos.com/calculator/kob9lxs9qf
        const float weightedColorVariance = sigmoid2(5.0f, angleThresholdForSmoothing, 40.0f, colorVarianceThresholdForSmoothing, imgColorVariance);

        // https://www.desmos.com/calculator/jwhpjq6ppj
        const float fineSimWeight = av_sigmoid(0.0f, 1.0f, 0.7f, -0.7f, refineSim);

        // if geometry variation is bigger than color variation => the fineDM is considered noisy

        // if depthEnergy > weightedColorVariance   => energyLowerThanVarianceWeight=0 => smooth
        // else:                                    => energyLowerThanVarianceWeight=1 => use fineDM
        // weightedColorVariance max value is 30, so if depthEnergy > 30 (which means depthAngle < 150�) energyLowerThanVarianceWeight will be 0
        // https://www.desmos.com/calculator/jzbweilb85
        const float energyLowerThanVarianceWeight = av_sigmoid(0.0f, 1.0f, 30.0f, weightedColorVariance, depthEnergy); // TODO: 30 => 60

        // https://www.desmos.com/calculator/ilsk7pthvz
        const float closeToRoughWeight = 1.0f - av_sigmoid(0.0f, 1.0f, 10.0f, 17.0f, abs(stepToRoughDM / sgmPixSize)); // TODO: 10 => 30

        // f(z) = c1 * s1(z_rought - z)^2 + c2 * s2(z-z_fused)^2 + coeff3 * s3*(z-z_smooth)^2

        const float depthOptStep = closeToRoughWeight * stepToRoughDM + // distance to smooth/robust input depth map
                                   (1.0f - closeToRoughWeight) * (energyLowerThanVarianceWeight * fineSimWeight * stepToFineDM + // distance to refined/noisy
                                                                 (1.0f - energyLowerThanVarianceWeight) * stepToSmoothDepth); // max angle in current depthMap

        out_optDepthSim.x = depthOpt + depthOptStep;

        out_optDepthSim.y = (1.0f - closeToRoughWeight) * (energyLowerThanVarianceWeight * fineSimWeight * refineSim + (1.0f - energyLowerThanVarianceWeight) * (depthEnergy / 20.0f));
    }

    out_optDepthSimPtr = out_optDepthSim;
}

ALICEVISION_DEPTHMAP_MTL_NS_END
