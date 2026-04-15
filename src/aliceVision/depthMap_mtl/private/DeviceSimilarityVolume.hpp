// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains declarations of pre-defined algorithms implemented in
 * Apple Metal.
 */

#pragma once

#include "aliceVision/depthMap_mtl/RefineParams.hpp"
#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/SgmParams.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/depthMap_mtl/private/DeviceMipmapImage.hpp>

#include <aliceVision/mvsData/ROI.hpp>

#include <memory>

#import <Metal/MTLDevice.h>
#import <Metal/MTLBuffer.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Initialize all the given similarity volume in device memory to the given value
 * @param[in,out] inout_volume_dmp The similarity volume in device memory
 * @param[in] value The value to initialize with
 * @param[in] dev The device to operate on
 */
void MTL_volumeInitTSim(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& inout_volume_dmp, TSim value, id<MTLDevice> dev);

/**
 * @brief Initialize all the given similarity volume in device memory to the given value
 * @param[in,out] inout_volume_dmp The similarity volume in device memory
 * @param[in] value The value to initialize with
 * @param[in] dev The device to operate on
 */
void MTL_volumeInitTSimRefine(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>>& inout_volume_dmp,
                              TSimRefine value,
                              id<MTLDevice> dev);

/**
 * @brief Compute the best / second best similarity volume for the given RC/TC
 * @param[out] out_volBestSim_dmp The best similarity volume in device memory
 * @param[out] out_volSecBestSim_dmp The second best similarity volume in device memory
 * @param[in] in_depths_dmp The R camera depth list in device memory
 * @param[in] rcDeviceCameraParamsId The R camera parameters id for array in device constant memory
 * @param[in] tcDeviceCameraParamsId The T camera parameters id for array in device constant memory
 * @param[in] rcDeviceMipmapImage The R mipmap image in device memory container
 * @param[in] tcDeviceMipmapImage The T mipmap image in device memory container
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] depthRange The volume depth range to compute
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_volumeComputeSimilarity(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& out_volBestSim_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& out_volSecBestSim_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& in_depths_dmp,
                                 const int rcDeviceCameraParamsId,
                                 const int tcDeviceCameraParamsId,
                                 const DeviceMipmapImage& rcDeviceMipmapImage,
                                 const DeviceMipmapImage& tcDeviceMipmapImage,
                                 const SgmParams& sgmParams,
                                 const Range& depthRange,
                                 const ROI& roi,
                                 id<MTLDevice> dev);

/**
 * @brief Update second best similarity volume uninitialized values with first
 *        best volume values
 * @param[in] in_volBestSim_dmp The best similarity volume in device memory
 * @param[out] inout_volSecBestSim_dmp The second best similarity volume in
 *             device memory
 * @param[in] dev The device to operate on
 */
void MTL_volumeUpdateUninitializedSimilarity(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volBestSim_dmp,
                                             const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& inout_volSecBestSim_dmp,
                                             id<MTLDevice> dev);

/**
 * @brief Filter / Optimize the given similarity volume
 * @param[out] out_volSimFiltered_dmp The output similarity volume in device memory
 * @param[in,out] inout_volSliceAccA_dmp The volume slice first accumulation buffer in device memory
 * @param[in,out] inout_volSliceAccB_dmp The volume slice second accumulation buffer in device memory
 * @param[in,out] inout_volAxisAcc_dmp The volume axisaccumulation buffer in device memory
 * @param[in] in_volSim_dmp The input similarity volume in device memory
 * @param[in] rcDeviceMipmapImage The R mipmap image in device memory container
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] lastDepthIndex The R camera last depth index
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_volumeOptimize(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& out_volSimFiltered_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volSliceAccA_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volSliceAccB_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>& inout_volAxisAcc_dmp,
                        const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volSim_dmp,
                        const DeviceMipmapImage& rcDeviceMipmapImage,
                        const SgmParams& sgmParams,
                        const int lastDepthIndex,
                        const ROI& roi,
                        id<MTLDevice> dev);

/**
 * @brief Retrieve the best depth/sim in the given similarity volume
 * @param[out] out_sgmDepthThicknessMap_dmp The output depth/thickness map in device memory
 * @param[out] out_sgmDepthSimMap_dmp The output best depth/sim map in device memory
 * @param[in] in_depths_dmp The R camera depth list in device memory
 * @param[in] in_volSim_dmp The input similarity volume in device memory
 * @param[in] rcDeviceCameraParamsId The R camera parameters id for array in device constant memory
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] depthRange The volume depth range to compute
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_volumeRetrieveBestDepth(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_sgmDepthThicknessMap_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_sgmDepthSimMap_dmp,
                                 bool computeDepthSimMap,
                                 const std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>& in_depths_dmp,
                                 const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volSim_dmp,
                                 const int rcDeviceCameraParamsId,
                                 const SgmParams& sgmParams,
                                 const Range& depthRange,
                                 const ROI& roi,
                                 id<MTLDevice> dev);

/**
 * @brief Refine the best similarity volume for the given RC / TC.
 * @param[out] inout_volSim_dmp The similarity volume in device memory
 * @param[in] in_sgmDepthPixSizeMap_dmp The SGM upscaled depth/pixSize map (useful to get middle depth) in device memory
 * @param[in] in_sgmNormalMap_dmpPtr (or nullptr) The SGM upscaled normal map in device memory
 * @param[in] rcDeviceCameraParamsId The R camera parameters id for array in device constant memory
 * @param[in] tcDeviceCameraParamsId The T camera parameters id for array in device constant memory
 * @param[in] rcDeviceMipmapImage The R mipmap image in device memory container
 * @param[in] tcDeviceMipmapImage The T mipmap image in device memory container
 * @param[in] refineParams The Refine parameters
 * @param[in] depthRange The volume depth range to compute
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_volumeRefineSimilarity(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>>& inout_volSim_dmp,
                                const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthPixSizeMap_dmp,
                                const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_sgmNormalMap_dmpPtr,
                                bool useSgmNormalMap,
                                const int rcDeviceCameraParamsId,
                                const int tcDeviceCameraParamsId,
                                const DeviceMipmapImage& rcDeviceMipmapImage,
                                const DeviceMipmapImage& tcDeviceMipmapImage,
                                const RefineParams& refineParams,
                                const Range& depthRange,
                                const ROI& roi,
                                id<MTLDevice> dev);

/**
 * @brief Retrieve the best depth/sim in the given refined similarity volume
 * @param[out] out_refineDepthSimMap_dmp The output refined and fused depth/sim map in device memory
 * @param[in] in_sgmDepthPixSizeMap_dmp The SGM upscaled depth/pixSize map (useful to get middle depth) in device memory
 * @param[in] in_volSim_dmp The similarity volume in device memory
 * @param[in] refineParams The Refine parameters
 * @param[in] depthRange The volume depth range to compute
 * @param[in] roi The 2D region of interest
 * @param[in] dev The device to operate on
 */
void MTL_volumeRefineBestDepth(const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& out_refineDepthSimMap_dmp,
                               const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthPixSizeMap_dmp,
                               const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>>& in_volSim_dmp,
                               const RefineParams& refineParams,
                               const ROI& roi,
                               id<MTLDevice> dev);

}  // namespace aliceVision::depthMap::mtl
