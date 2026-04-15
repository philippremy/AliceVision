// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceCache.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>

#include <aliceVision/system/Logger.hpp>

#include <memory>
#include <mutex>
#include <ranges>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceImpl.hpp>

#import <Foundation/NSArray.h>
#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

#pragma mark Standalone Functions

/**
 * @brief Filters a given list of devices and returns the device most suitable
 *        to perform DepthMap computation
 *
 * The relevant factors are:
 * 1. Not low power (+ 150)
 * 2. Unified Memory (+ 100)
 * 3. Supports `MTLReadWriteTextureTier2` (+ 50)
 */
id<MTLDevice> findPreferredDevice(const std::vector<id<MTLDevice>>& availableDevices)
{
    uint64_t bestScore = 0;
    uint64_t bestDeviceID = 0;
    for (const auto& dev : availableDevices)
    {
        // Default to one higher than nothing
        uint64_t score = 1;
        if (![dev isLowPower])
            score += 150;
        if ([dev hasUnifiedMemory])
            score += 100;
        if ([dev readWriteTextureSupport] == MTLReadWriteTextureTier2)
            score += 50;

        if (score > bestScore)
        {
            bestScore = score;
            bestDeviceID = [dev registryID];
        }
    }

    // Explicit copy
    // SAFETY: It is guaranteed that this deviceID exists
    return *std::ranges::find_if(availableDevices, [&](const auto& dev) { return [dev registryID] == bestDeviceID; });
}

#pragma mark Static class members

// Static Class Members must be defined outside of the class
std::mutex DeviceManager::initMutex = std::mutex();
DeviceManager* DeviceManager::singleton = nullptr;

// Static Class Functions must be defined outside of the class
DeviceManager& DeviceManager::instance()
{
    initMutex.lock();
    if (!singleton)
        singleton = new DeviceManager();
    initMutex.unlock();
    return *singleton;
}

#pragma mark Class methods

// Constructor searches for available devices on the system
DeviceManager::DeviceManager()
{
    NSArray<id<MTLDevice>>* availableDevices = MTLCopyAllDevices();
    NSUInteger deviceCount = [availableDevices count];

    if (deviceCount == 0)
        ALICEVISION_LOG_WARNING("No Apple Metal devices found on this system!");

    // Single allocations
    this->_devices.reserve(deviceCount);

    // Push devices
    for (id<MTLDevice> dev in availableDevices)
        this->_devices.push_back(dev);

    // Find the preferred device
    this->_preferredDevice = findPreferredDevice(this->_devices);

    // Create command managers
    for (id<MTLDevice> dev : this->_devices)
        this->_cmdManagersPerDevice.emplace([dev registryID], std::unique_ptr<DeviceCommandManager>(new DeviceCommandManager(dev)));

    // Create device caches
    for (id<MTLDevice> dev : this->_devices)
        this->_cachesPerDevice.emplace([dev registryID], std::unique_ptr<DeviceCache>(new DeviceCache(dev)));
}

id<MTLDevice> DeviceManager::preferredDevice() { return this->_preferredDevice; }

id<MTLDevice> DeviceManager::deviceForIdx(unsigned int idx) { return this->_devices[idx]; }

size_t DeviceManager::mtlDeviceCount() const { return this->_devices.size(); }

DeviceCommandManager& DeviceManager::getCMDManager(id<MTLDevice> forDevice) { return *this->_cmdManagersPerDevice.at([forDevice registryID]); }

DeviceCache& DeviceManager::getDeviceCache(id<MTLDevice> forDevice) { return *this->_cachesPerDevice.at([forDevice registryID]); }

}  // namespace aliceVision::depthMap::mtl
