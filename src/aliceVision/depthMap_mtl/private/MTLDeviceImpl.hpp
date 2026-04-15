// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains the implementation of the MTLDeviceImpl forward declared
 * type
 */

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>

#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief A wrapper type that wraps an instance of a MTLDevice
 */
struct MTLDeviceImpl
{
    /**
     * @brief No default constructor
     */
    MTLDeviceImpl() = delete;

    /**
     * @brief Copies the ARC pointer
     */
    explicit MTLDeviceImpl(id<MTLDevice> dev) { this->_dev = dev; }

    /**
     * @brief Copies the ARC pointer
     */
    MTLDeviceImpl(const MTLDeviceImpl& other) { this->_dev = other._dev; }

    /**
     * @brief Copies the ARC pointer
     */
    MTLDeviceImpl(const MTLDeviceImpl&& other) { this->_dev = other._dev; }

    /**
     * @brief Copies the ARC pointer
     */
    MTLDeviceImpl operator=(const MTLDeviceImpl& other) { return MTLDeviceImpl(other._dev); }

    /**
     * @brief Copies the ARC pointer
     */
    MTLDeviceImpl operator=(const MTLDeviceImpl&& other) { return MTLDeviceImpl(other._dev); }

    id<MTLDevice> operator->() { return _dev; }

    id<MTLDevice> operator*() { return _dev; }

  private:
    __strong id<MTLDevice> _dev;  //< Strong (i.e., owning pointer) to the MTLDevice
};

}  // namespace aliceVision::depthMap::mtl
