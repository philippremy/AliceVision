// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains routines used for path computation
 */

#pragma once

#include <aliceVision/depthMap_mtl/DevicePatchPattern.hpp>
#include <aliceVision/depthMap_mtl/Namespace.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/depthMap_mtl/private/DeviceCameraParams.hpp>

/* Metal Headers */
#include <aliceVision/depthMap_mtl/metal/Color.hpp>
#include <aliceVision/depthMap_mtl/metal/DeviceTextureSamplers.hpp>
#include <aliceVision/depthMap_mtl/metal/Math.hpp>
#include <aliceVision/depthMap_mtl/metal/Matrix.hpp>
#include <aliceVision/depthMap_mtl/metal/SimStat.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

struct Patch
{
    float3 p;  //< 3d point
    float3 n;  //< normal
    float3 x;  //< x axis
    float3 y;  //< y axis
    float d;   //< pixel size
};

inline float3 get3DPointForPixelAndDepthFromRC(constant const DeviceCameraParams& deviceCamParams, thread const float2& pix, float depth)
{
    float3 rpv = M3x3mulV2(deviceCamParams.iP, pix);
    av_normalize(rpv);
    return deviceCamParams.C + rpv * depth;
}

inline float3 get3DPointForPixelAndFrontoParellePlaneRC(constant const DeviceCameraParams& deviceCamParams,
                                                        thread const float2& pix,
                                                        float fpPlaneDepth)
{
    const float3 planep = deviceCamParams.C + deviceCamParams.ZVect * fpPlaneDepth;
    float3 v = M3x3mulV2(deviceCamParams.iP, pix);
    av_normalize(v);
    return linePlaneIntersect(deviceCamParams.C, v, planep, deviceCamParams.ZVect);
}

inline float computePixSize(constant const DeviceCameraParams& deviceCamParams, thread const float3& p)
{
    const float2 rp = project3DPoint(deviceCamParams.P, p);
    const float2 rp1 = rp + float2(1.0f, 0.0f);

    float3 refvect = M3x3mulV2(deviceCamParams.iP, rp1);
    av_normalize(refvect);
    return pointLineDistance3D(p, deviceCamParams.C, refvect);
}

inline void computeRotCSEpip(thread Patch& ptch,
                             constant const DeviceCameraParams& rcDeviceCamParams,
                             constant const DeviceCameraParams& tcDeviceCamParams)
{
    // Vector from the reference camera to the 3d point
    float3 v1 = rcDeviceCamParams.C - ptch.p;
    // Vector from the target camera to the 3d point
    float3 v2 = tcDeviceCamParams.C - ptch.p;
    av_normalize(v1);
    av_normalize(v2);

    // y has to be orthogonal to the epipolar plane
    // n has to be on the epipolar plane
    // x has to be on the epipolar plane

    ptch.y = av_cross(v1, v2);
    av_normalize(ptch.y);  // TODO: v1 & v2 are already normalized

    ptch.n = (v1 + v2) / 2.0f;  // IMPORTANT !!!
    av_normalize(ptch.n);       // TODO: v1 & v2 are already normalized
    // ptch.n = sg_s_r.ZVect; //IMPORTANT !!!

    ptch.x = av_cross(ptch.y, ptch.n);
    av_normalize(ptch.x);
}

inline void computeRcTcMipmapLevels(thread float& out_rcMipmapLevel,
                                    thread float& out_tcMipmapLevel,
                                    thread const float mipmapLevel,
                                    constant const DeviceCameraParams& rcDeviceCamParams,
                                    constant const DeviceCameraParams& tcDeviceCamParams,
                                    thread const float2& rp0,
                                    thread const float2& tp0,
                                    thread const float3& p0)
{
    // get p0 depth from the R camera
    const float rcDepth = av_size(rcDeviceCamParams.C - p0);

    // get p0 depth from the T camera
    const float tcDepth = av_size(tcDeviceCamParams.C - p0);

    // get R p0 corresponding pixel + 1x
    const float2 rp1 = rp0 + float2(1.f, 0.f);

    // get T p0 corresponding pixel + 1x
    const float2 tp1 = tp0 + float2(1.f, 0.f);

    // get rp1 3d point
    float3 rpv = M3x3mulV2(rcDeviceCamParams.iP, rp1);
    av_normalize(rpv);
    const float3 prp1 = rcDeviceCamParams.C + rpv * rcDepth;

    // get tp1 3d point
    float3 tpv = M3x3mulV2(tcDeviceCamParams.iP, tp1);
    av_normalize(tpv);
    const float3 ptp1 = tcDeviceCamParams.C + tpv * tcDepth;

    // compute 3d distance between p0 and rp1 3d point
    const float rcDist = av_dist(p0, prp1);

    // compute 3d distance between p0 and tp1 3d point
    const float tcDist = av_dist(p0, ptp1);

    // compute Rc/Tc distance factor
    const float distFactor = rcDist / tcDist;

    // set output R and T mipmap level
    if (distFactor < 1.f)
    {
        // T camera has a lower resolution (1 Rc pixSize < 1 Tc pixSize)
        out_tcMipmapLevel = mipmapLevel - log2(1.f / distFactor);

        if (out_tcMipmapLevel < 0.f)
        {
            out_rcMipmapLevel = mipmapLevel + abs(out_tcMipmapLevel);
            out_tcMipmapLevel = 0.f;
        }
    }
    else
    {
        // T camera has a higher resolution (1 Rc pixSize > 1 Tc pixSize)
        out_rcMipmapLevel = mipmapLevel;
        out_tcMipmapLevel = mipmapLevel + log2(distFactor);
    }
}

/**
 * @brief Compute Normalized Cross-Correlation of a patch with an user custom patch pattern.
 *
 * @tparam TInvertAndFilter invert and filter output similarity value
 *
 * @param[in] rcDeviceCameraParamsId the R camera parameters in device constant memory array
 * @param[in] tcDeviceCameraParamsId the T camera parameters in device constant memory array
 * @param[in] rcMipmapImage_tex the R camera mipmap image texture
 * @param[in] tcMipmapImage_tex the T camera mipmap image texture
 * @param[in] rcLevelWidth the R camera image width at given mipmapLevel
 * @param[in] rcLevelHeight the R camera image height at given mipmapLevel
 * @param[in] tcLevelWidth the T camera image width at given mipmapLevel
 * @param[in] tcLevelHeight the T camera image height at given mipmapLevel
 * @param[in] mipmapLevel the workflow current mipmap level (e.g. SGM=1.f, Refine=0.f)
 * @param[in] invGammaC the inverted strength of grouping by color similarity
 * @param[in] invGammaP the inverted strength of grouping by proximity
 * @param[in] useConsistentScale enable consistent scale patch comparison
 * @param[in] patch the input patch struct
 *
 * @return similarity value in range (-1.f, 0.f) or (0.f, 1.f) if TinvertAndFilter enabled
 *         special cases:
 *          -> infinite similarity value: 1
 *          -> invalid/uninitialized/masked similarity: MAXFLOAT
 */
template<bool TInvertAndFilter>
inline float compNCCby3DptsYK_customPatchPattern(constant const DeviceCameraParams& rcDeviceCamParams,
                                                 constant const DeviceCameraParams& tcDeviceCamParams,
                                                 thread const texture2d<MTLRGBABaseType, access::sample>& rcMipmapImage_tex,
                                                 thread const texture2d<MTLRGBABaseType, access::sample>& tcMipmapImage_tex,
                                                 const unsigned int rcLevelWidth,
                                                 const unsigned int rcLevelHeight,
                                                 const unsigned int tcLevelWidth,
                                                 const unsigned int tcLevelHeight,
                                                 const float mipmapLevel,
                                                 const float invGammaC,
                                                 const float invGammaP,
                                                 const bool useConsistentScale,
                                                 thread const Patch& patch,
                                                 constant const DevicePatchPattern& constantPatchPattern_d)
{
    // get R and T image 2d coordinates from patch center 3d point
    const float2 rp = project3DPoint(rcDeviceCamParams.P, patch.p);
    const float2 tp = project3DPoint(tcDeviceCamParams.P, patch.p);

    // image 2d coordinates margin
    const float dd = 2.f;  // TODO: proper wsh handling

    // check R and T image 2d coordinates
    if ((rp.x < dd) || (rp.x > float(rcLevelWidth - 1) - dd) || (tp.x < dd) || (tp.x > float(tcLevelWidth - 1) - dd) || (rp.y < dd) ||
        (rp.y > float(rcLevelHeight - 1) - dd) || (tp.y < dd) || (tp.y > float(tcLevelHeight - 1) - dd))
    {
        return MAXFLOAT;  // uninitialized
    }

    // compute inverse width / height
    // note: useful to compute normalized coordinates
    const float rcInvLevelWidth = 1.f / float(rcLevelWidth);
    const float rcInvLevelHeight = 1.f / float(rcLevelHeight);
    const float tcInvLevelWidth = 1.f / float(tcLevelWidth);
    const float tcInvLevelHeight = 1.f / float(tcLevelHeight);

    // get patch center pixel alpha at the given mipmap image level
    const float rcAlpha =
      rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((rp.x + 0.5f) * rcInvLevelWidth, (rp.y + 0.5f) * rcInvLevelHeight), mipmapLevel)
        .w;  // alpha only
    const float tcAlpha =
      tcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((tp.x + 0.5f) * tcInvLevelWidth, (tp.y + 0.5f) * tcInvLevelHeight), mipmapLevel)
        .w;  // alpha only

    // check the alpha values of the patch pixel center of the R and T cameras
    if (rcAlpha < ALICEVISION_DEPTHMAP_RC_MIN_ALPHA || tcAlpha < ALICEVISION_DEPTHMAP_TC_MIN_ALPHA)
    {
        return MAXFLOAT;  // masked
    }

    // initialize R and T mipmap image level at the given mipmap image level
    float rcMipmapLevel = mipmapLevel;
    float tcMipmapLevel = mipmapLevel;

    // update R and T mipmap image level in order to get consistent scale patch comparison
    if (useConsistentScale)
    {
        computeRcTcMipmapLevels(rcMipmapLevel, tcMipmapLevel, mipmapLevel, rcDeviceCamParams, tcDeviceCamParams, rp, tp, patch.p);
    }

    // output similarity initialization
    float fsim = 0.f;
    float wsum = 0.f;

    for (int s = 0; s < constantPatchPattern_d.nbSubparts; ++s)
    {
        // create and initialize patch subpart SimStat
        simStat sst;

        // get patch pattern subpart
        constant const DevicePatchPatternSubpart& subpart = constantPatchPattern_d.subparts[s];

        // compute patch center color (CIELAB) at subpart level resolution
        const float4 rcCenterColor = float4(rcMipmapImage_tex.sample(
          TEX_SAMPLER_NORM, float2((rp.x + 0.5f) * rcInvLevelWidth, (rp.y + 0.5f) * rcInvLevelHeight), rcMipmapLevel + subpart.level));
        const float4 tcCenterColor = float4(tcMipmapImage_tex.sample(
          TEX_SAMPLER_NORM, float2((tp.x + 0.5f) * tcInvLevelWidth, (tp.y + 0.5f) * tcInvLevelHeight), tcMipmapLevel + subpart.level));

        if (subpart.isCircle)
        {
            for (int c = 0; c < subpart.nbCoordinates; ++c)
            {
                // get patch relative coordinates
                constant const float2& relativeCoord = subpart.coordinates[c];

                // get 3d point from relative coordinates
                const float3 p = patch.p + patch.x * float(patch.d * relativeCoord.x) + patch.y * float(patch.d * relativeCoord.y);

                // get R and T image 2d coordinates from 3d point
                const float2 rpc = project3DPoint(rcDeviceCamParams.P, p);
                const float2 tpc = project3DPoint(tcDeviceCamParams.P, p);

                // get R and T image color (CIELAB) from 2d coordinates
                const float4 rcPatchCoordColor = float4(rcMipmapImage_tex.sample(
                  TEX_SAMPLER_NORM, float2((rpc.x + 0.5f) * rcInvLevelWidth, (rpc.y + 0.5f) * rcInvLevelHeight), rcMipmapLevel + subpart.level));
                const float4 tcPatchCoordColor = float4(tcMipmapImage_tex.sample(
                  TEX_SAMPLER_NORM, float2((tpc.x + 0.5f) * tcInvLevelWidth, (tpc.y + 0.5f) * tcInvLevelHeight), tcMipmapLevel + subpart.level));

                // compute weighting based on color difference to the center pixel of the patch:
                // - low value (close to 0) means that the color is different from the center pixel (ie. strongly supported surface)
                // - high value (close to 1) means that the color is close the center pixel (ie. uniform color)
                const float w =
                  CostYKfromLab(rcCenterColor, rcPatchCoordColor, invGammaC) * CostYKfromLab(tcCenterColor, tcPatchCoordColor, invGammaC);

                // update simStat
                sst.update(rcPatchCoordColor.x, tcPatchCoordColor.x, w);
            }
        }
        else  // full patch pattern
        {
            for (int yp = -subpart.wsh; yp <= subpart.wsh; ++yp)
            {
                for (int xp = -subpart.wsh; xp <= subpart.wsh; ++xp)
                {
                    // get 3d point
                    const float3 p =
                      patch.p + patch.x * float(patch.d * float(xp) * subpart.downscale) + patch.y * float(patch.d * float(yp) * subpart.downscale);

                    // get R and T image 2d coordinates from 3d point
                    const float2 rpc = project3DPoint(rcDeviceCamParams.P, p);
                    const float2 tpc = project3DPoint(tcDeviceCamParams.P, p);

                    // get R and T image color (CIELAB) from 2d coordinates
                    const float4 rcPatchCoordColor = float4(rcMipmapImage_tex.sample(
                      TEX_SAMPLER_NORM, float2((rpc.x + 0.5f) * rcInvLevelWidth, (rpc.y + 0.5f) * rcInvLevelHeight), rcMipmapLevel + subpart.level));
                    const float4 tcPatchCoordColor = float4(tcMipmapImage_tex.sample(
                      TEX_SAMPLER_NORM, float2((tpc.x + 0.5f) * tcInvLevelWidth, (tpc.y + 0.5f) * tcInvLevelHeight), tcMipmapLevel + subpart.level));

                    // compute weighting based on:
                    // - color difference to the center pixel of the patch:
                    //    - low value (close to 0) means that the color is different from the center pixel (ie. strongly supported surface)
                    //    - high value (close to 1) means that the color is close the center pixel (ie. uniform color)
                    // - distance in image to the center pixel of the patch:
                    //    - low value (close to 0) means that the pixel is close to the center of the patch
                    //    - high value (close to 1) means that the pixel is far from the center of the patch
                    const float w = CostYKfromLab(xp, yp, rcCenterColor, rcPatchCoordColor, invGammaC, invGammaP) *
                                    CostYKfromLab(xp, yp, tcCenterColor, tcPatchCoordColor, invGammaC, invGammaP);

                    // update simStat
                    sst.update(rcPatchCoordColor.x, tcPatchCoordColor.x, w);
                }
            }
        }

        // compute patch subpart similarity
        const float fsimSubpart = sst.computeWSim();

        // similarity value in range (-1.f, 0.f) or invalid
        if (fsimSubpart < 0.f)
        {
            // add patch pattern subpart similarity to patch similarity
            if (TInvertAndFilter)
            {
                // invert and filter similarity
                // apply sigmoid see: https://www.desmos.com/calculator/skmhf1gpyf
                // best similarity value was -1, worst was 0
                // best similarity value is 1, worst is still 0
                const float fsimInverted = av_sigmoid(0.0f, 1.0f, 0.7f, -0.7f, fsimSubpart);
                fsim += fsimInverted * subpart.weight;
            }
            else
            {
                // weight and add similarity
                fsim += fsimSubpart * subpart.weight;
            }

            // sum subpart weight
            wsum += subpart.weight;
        }
    }

    // invalid patch similarity
    if (wsum == 0.f)
    {
        return MAXFLOAT;
    }

    if (TInvertAndFilter)
    {
        // for now, we do not average
        return fsim;
    }

    // output average similarity
    return (fsim / wsum);
}

/**
 * @brief Compute Normalized Cross-Correlation of a full square patch at given half-width.
 *
 * @tparam TInvertAndFilter invert and filter output similarity value
 *
 * @param[in] rcDeviceCameraParamsId the R camera parameters in device constant memory array
 * @param[in] tcDeviceCameraParamsId the T camera parameters in device constant memory array
 * @param[in] rcMipmapImage_tex the R camera mipmap image texture
 * @param[in] tcMipmapImage_tex the T camera mipmap image texture
 * @param[in] rcLevelWidth the R camera image width at given mipmapLevel
 * @param[in] rcLevelHeight the R camera image height at given mipmapLevel
 * @param[in] tcLevelWidth the T camera image width at given mipmapLevel
 * @param[in] tcLevelHeight the T camera image height at given mipmapLevel
 * @param[in] mipmapLevel the workflow current mipmap level (e.g. SGM=1.f, Refine=0.f)
 * @param[in] wsh the half-width of the patch
 * @param[in] invGammaC the inverted strength of grouping by color similarity
 * @param[in] invGammaP the inverted strength of grouping by proximity
 * @param[in] useConsistentScale enable consistent scale patch comparison
 * @param[in] tcLevelWidth the T camera image width at given mipmapLevel
 * @param[in] patch the input patch struct
 *
 * @return similarity value in range (-1.f, 0.f) or (0.f, 1.f) if TinvertAndFilter enabled
 *         special cases:
 *          -> infinite similarity value: 1
 *          -> invalid/uninitialized/masked similarity: CUDART_INF_F
 */
template<bool TInvertAndFilter>
inline float compNCCby3DptsYK(constant const DeviceCameraParams& rcDeviceCamParams,
                              constant const DeviceCameraParams& tcDeviceCamParams,
                              thread const texture2d<MTLRGBABaseType, access::sample>& rcMipmapImage_tex,
                              thread const texture2d<MTLRGBABaseType, access::sample>& tcMipmapImage_tex,
                              const unsigned int rcLevelWidth,
                              const unsigned int rcLevelHeight,
                              const unsigned int tcLevelWidth,
                              const unsigned int tcLevelHeight,
                              const float mipmapLevel,
                              const int wsh,
                              const float invGammaC,
                              const float invGammaP,
                              const bool useConsistentScale,
                              thread const Patch& patch)
{
    // get R and T image 2d coordinates from patch center 3d point
    const float2 rp = project3DPoint(rcDeviceCamParams.P, patch.p);
    const float2 tp = project3DPoint(tcDeviceCamParams.P, patch.p);

    // image 2d coordinates margin
    const float dd = wsh + 2.0f; // TODO: FACA

    // check R and T image 2d coordinates
    if((rp.x < dd) || (rp.x > float(rcLevelWidth  - 1) - dd) ||
       (tp.x < dd) || (tp.x > float(tcLevelWidth  - 1) - dd) ||
       (rp.y < dd) || (rp.y > float(rcLevelHeight - 1) - dd) ||
       (tp.y < dd) || (tp.y > float(tcLevelHeight - 1) - dd))
    {
        return MAXFLOAT; // uninitialized
    }

    // compute inverse width / height
    // note: useful to compute normalized coordinates
    const float rcInvLevelWidth  = 1.f / float(rcLevelWidth);
    const float rcInvLevelHeight = 1.f / float(rcLevelHeight);
    const float tcInvLevelWidth  = 1.f / float(tcLevelWidth);
    const float tcInvLevelHeight = 1.f / float(tcLevelHeight);

    // initialize R and T mipmap image level at the given mipmap image level
    float rcMipmapLevel = mipmapLevel;
    float tcMipmapLevel = mipmapLevel;

    // update R and T mipmap image level in order to get consistent scale patch comparison
    if(useConsistentScale)
    {
        computeRcTcMipmapLevels(rcMipmapLevel, tcMipmapLevel, mipmapLevel, rcDeviceCamParams, tcDeviceCamParams, rp, tp, patch.p);
    }

    // create and initialize SimStat struct
    simStat sst;

    // compute patch center color (CIELAB) at R and T mipmap image level
    const float4 rcCenterColor = float4(rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((rp.x + 0.5f) * rcInvLevelWidth, (rp.y + 0.5f) * rcInvLevelHeight), rcMipmapLevel));
    const float4 tcCenterColor = float4(tcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((tp.x + 0.5f) * tcInvLevelWidth, (tp.y + 0.5f) * tcInvLevelHeight), tcMipmapLevel));

    // check the alpha values of the patch pixel center of the R and T cameras
    if(rcCenterColor.w < ALICEVISION_DEPTHMAP_RC_MIN_ALPHA || tcCenterColor.w < ALICEVISION_DEPTHMAP_TC_MIN_ALPHA)
    {
        return MAXFLOAT; // masked
    }

    // compute patch (wsh*2+1)x(wsh*2+1)
    for(int yp = -wsh; yp <= wsh; ++yp)
    {
        for(int xp = -wsh; xp <= wsh; ++xp)
        {
            // get 3d point
            const float3 p = patch.p + patch.x * float(patch.d * float(xp)) + patch.y * float(patch.d * float(yp));

            // get R and T image 2d coordinates from 3d point
            const float2 rpc = project3DPoint(rcDeviceCamParams.P, p);
            const float2 tpc = project3DPoint(tcDeviceCamParams.P, p);

            // get R and T image color (CIELAB) from 2d coordinates
            const float4 rcPatchCoordColor = float4(rcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((rpc.x + 0.5f) * rcInvLevelWidth, (rpc.y + 0.5f) * rcInvLevelHeight), rcMipmapLevel));
            const float4 tcPatchCoordColor = float4(tcMipmapImage_tex.sample(TEX_SAMPLER_NORM, float2((tpc.x + 0.5f) * tcInvLevelWidth, (tpc.y + 0.5f) * tcInvLevelHeight), tcMipmapLevel));

            // compute weighting based on:
            // - color difference to the center pixel of the patch:
            //    - low value (close to 0) means that the color is different from the center pixel (ie. strongly supported surface)
            //    - high value (close to 1) means that the color is close the center pixel (ie. uniform color)
            // - distance in image to the center pixel of the patch:
            //    - low value (close to 0) means that the pixel is close to the center of the patch
            //    - high value (close to 1) means that the pixel is far from the center of the patch
            const float w = CostYKfromLab(xp, yp, rcCenterColor, rcPatchCoordColor, invGammaC, invGammaP) * CostYKfromLab(xp, yp, tcCenterColor, tcPatchCoordColor, invGammaC, invGammaP);

            // update simStat
            sst.update(rcPatchCoordColor.x, tcPatchCoordColor.x, w);
        }
    }

    if(TInvertAndFilter)
    {
        // compute patch similarity
        const float fsim = sst.computeWSim();

        // invert and filter similarity
        // apply sigmoid see: https://www.desmos.com/calculator/skmhf1gpyf
        // best similarity value was -1, worst was 0
        // best similarity value is 1, worst is still 0
        return av_sigmoid(0.0f, 1.0f, 0.7f, -0.7f, fsim);
    }

    // compute output patch similarity
    return sst.computeWSim();
}

/**
 * @brief Subpixel refine by Stereo Matching with Color-Weighted Correlation, Hierarchical Belief Propagation,
 *        and Occlusion Handling Qingxiong pami08.
 *
 * @note Quadratic polynomial interpolation is used to approximate the cost function between
 *       three discrete depth candidates: d, dA, and dB.
 *
 * @see https://pubmed.ncbi.nlm.nih.gov/19147877/
 *
 * @param[in] depths the 3 depths candidates (depth-1, depth, depth+1)
 * @param[in] sims the similarity of the 3 depths candidates
 *
 * @return refined depth value
 */
inline float refineDepthSubPixel(thread const float3& depths, thread const float3& sims)
{
    // TODO: get formula back from paper as it has been lost by encoding.
    // d is the discrete depth with the minimal cost, dA ? d A 1, and dB ? d B 1. The cost function is approximated as
    // f?x? ? ax2 B bx B c.

    float simM1 = sims.x;
    float sim = sims.y;
    float simP1 = sims.z;
    simM1 = (simM1 + 1.0f) / 2.0f;
    sim = (sim + 1.0f) / 2.0f;
    simP1 = (simP1 + 1.0f) / 2.0f;

    // sim is supposed to be the best one (so the smallest one)
    if((simM1 < sim) || (simP1 < sim))
        return depths.y; // return the input

    float dispStep = -((simP1 - simM1) / (2.0f * (simP1 + simM1 - 2.0f * sim)));

    float floatDepthM1 = depths.x;
    float floatDepthP1 = depths.z;

    //-1 : floatDepthM1
    // 0 : floatDepth
    //+1 : floatDepthP1
    // linear function fit
    // f(x)=a*x+b
    // floatDepthM1=-a+b
    // floatDepthP1= a+b
    // a = b - floatDepthM1
    // floatDepthP1=2*b-floatDepthM1
    float b = (floatDepthP1 + floatDepthM1) / 2.0f;
    float a = b - floatDepthM1;

    float interpDepth = a * dispStep + b;

    // Ensure that the interpolated value is isfinite  (i.e. neither infinite nor NaN)
    if(!isfinite(interpDepth) || interpDepth <= 0.0f)
        return depths.y; // return the input

    return interpDepth;
}

ALICEVISION_DEPTHMAP_MTL_NS_END
