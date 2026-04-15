// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains a class handling Metal device management
 */

#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

/* Forward Declarations */
class DeviceCommandManager;
class DeviceCache;

/**
 * @brief A class handling Metal device discovery
 */
class DeviceManager final
{
  public:
    /**
     * @brief Returns the initialized singelton instance
     */
    static DeviceManager& instance();

    /* Only a Singleton, cannot be copied or moved */
    DeviceManager(const DeviceManager&) = delete;
    DeviceManager(const DeviceManager&&) = delete;
    DeviceManager operator=(const DeviceManager&) = delete;
    DeviceManager operator=(const DeviceManager&&) = delete;

#pragma mark Device Inspection

    /**
     * @brief Gets the preferred device
     */
    id<MTLDevice> preferredDevice();

    /**
     * @brief Returns the device for the given index in the ordered device list
     */
    id<MTLDevice> deviceForIdx(unsigned int idx);

    /**
     * @brief Returns the number of Metal devices available to the application
     */
    size_t mtlDeviceCount() const;

#pragma mark Device Command Management

    /**
     * @brief Returns the DeviceCommandManager instance for the requested
     *        device
     *
     * @param[in] forDevice The MTLDevice to get the DeviceCommandManager for
     *
     * @returns A reference to the DeviceCommandManager instance
     */
    DeviceCommandManager& getCMDManager(id<MTLDevice> forDevice);

#pragma mark Device Resource Management

    /**
     * @brief Returns the DeviceCommandManager instance for the requested
     *        device
     *
     * @param[in] forDevice The MTLDevice to get the DeviceCommandManager for
     *
     * @returns A reference to the DeviceCommandManager instance
     */
    DeviceCache& getDeviceCache(id<MTLDevice> forDevice);

  private:
    /**
     * @brief Default constructor available for instance() method
     */
    DeviceManager();

    static std::mutex initMutex;      //< The initialization mutex
    static DeviceManager* singleton;  //< The class instance singleton

    id<MTLDevice> _preferredDevice;       //< The preferred device
    std::vector<id<MTLDevice>> _devices;  //< The available system devices

    std::unordered_map<uint64_t, std::unique_ptr<DeviceCommandManager>> _cmdManagersPerDevice;  //< The command manager instances per device
    std::unordered_map<uint64_t, std::unique_ptr<DeviceCache>> _cachesPerDevice;                //< The DeviceCache instances per device
};

}  // namespace aliceVision::depthMap::mtl
