// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains a class handling Metal device resource caching
 */

#pragma once

#include "aliceVision/depthMap_mtl/Config.h"
#include <aliceVision/depthMap_mtl/DevicePatchPattern.hpp>
#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/depthMap_mtl/private/DeviceCameraParams.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceMipmapImage.hpp>
#include <aliceVision/depthMap_mtl/private/LRUCache.hpp>
#include <aliceVision/depthMap_mtl/private/LRUCameraCache.hpp>
#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

#include <aliceVision/image/Image.hpp>
#include <aliceVision/image/pixelTypes.hpp>
#include <aliceVision/mvsUtils/ImagesCache.hpp>

#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

class DeviceCache final
{
    /* Make DeviceManager a friend, so it can call the private constructor */
    friend class DeviceManager;

  public:
    /* No default constructor */
    DeviceCache() = delete;

    /* No copy/move constructors */
    DeviceCache(const DeviceCache&) = delete;
    DeviceCache(const DeviceCache&&) = delete;
    DeviceCache operator=(const DeviceCache&) = delete;
    DeviceCache operator=(const DeviceCache&&) = delete;

    /**
     * @brief Clear the current device cache
     */
    void clearCache();

    /**
     * @brief Build the current device cache
     *
     * @param[in] maxMipmapImages The maximum number of mipmap images in the
     *            current device cache
     * @param[in] maxCameraParams The maximum number of camera parameters in
     *            the current device cache
     */
    void buildCache(int maxMipmapImages, int maxCameraParams);

    /**
     * @brief Add a mipmap image in current gpu device cache
     *
     * @param[in] camId The camera index in the ImagesCache / MultiViewParams
     * @param[in] minDownscale The min downscale factor
     * @param[in] maxDownscale The max downscale factor
     * @param[in,out] imageCache The image cache to get host-side data
     * @param[in] mp The multi-view parameters
     */
    void addMipmapImage(int camId,
                        int minDownscale,
                        int maxDownscale,
                        mvsUtils::ImagesCache<image::Image<image::RGBAfColor>>& imageCache,
                        const mvsUtils::MultiViewParams& mp);

    /**
     * @brief Add a camera parameters structure in current gpu device cache
     *
     * @param[in] camId The camera index in the ImagesCache / MultiViewParams
     * @param[in] downscale The downscale to apply on the device
     * @param[in] mp The multi-view parameters
     */
    void addCameraParams(int camId, int downscale, const mvsUtils::MultiViewParams& mp);

    /**
     * @brief Add a camera parameters structure in current gpu device cache
     *
     * @param[in] camId The camera index in the ImagesCache / MultiViewParams
     * @param[in] downscale The downscale to apply on the device
     * @param[in] mp The multi-view parameters
     */
    void setCustomPatchPattern(const DevicePatchPattern& patchPattern);

    /**
     * @brief Request a mipmap image in current gpu device cache
     *
     * @param[in] camId The camera index in the ImagesCache / MultiViewParams
     * @param[in] mp The multi-view parameters
     *
     * @return DeviceMipmapImage
     */
    const DeviceMipmapImage& requestMipmapImage(int camId, const mvsUtils::MultiViewParams& mp);

    /**
     * @brief Request a camera parameters id in current gpu device cache
     *
     * @param[in] camId The camera index in the ImagesCache / MultiViewParams
     * @param[in] downscale The downscale to apply on the device
     * @param[in] mp The multi-view parameters
     *
     * @return Device camera parameters id
     */
    int requestCameraParamsId(int camId, int downscale, const mvsUtils::MultiViewParams& mp);

    /**
     * @brief Returns the device accessible camera parameter array
     *
     * @return The constantCameraParametersArray_d array
     */
    id<MTLBuffer> getCameraParams() const;

    /**
     * @brief Returns the device accessible camera parameter array
     *
     * @return The constantCameraParametersArray_d array
     */
    const DevicePatchPattern& getCustomPatchPattern() const;

  private:
    /**
     * @brief Private constructor which associates the instance to be created
     *        with the specified MTLDevice
     *
     * This constructor is private and should only be called by the friend
     * class DeviceManager.
     */
    explicit DeviceCache(id<MTLDevice> dev);

    const __strong id<MTLDevice> _dev;  //< The associated device

    LRUCameraIdCache _mipmapCache;     //< The Camera ID cache
    LRUCameraCache _cameraParamCache;  //< The Camera Parameter Cache

    DevicePatchPattern _devPatchPattern = DevicePatchPattern();  //< The custom patch pattern (to be pushed as a push constant)
    std::unique_ptr<MTLDeviceMemory<DeviceCameraParams, 1, MemoryType::HostVisible>>
      _devCameraParams;                                                //< The device camera parameters (to be pushed as a push constant)
    std::vector<std::unique_ptr<DeviceMipmapImage>> _mipmappedImages;  //< The cached mipmapped device images
};

}  // namespace aliceVision::depthMap::mtl
