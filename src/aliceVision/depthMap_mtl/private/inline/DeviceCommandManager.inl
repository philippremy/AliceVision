// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#ifndef DEVICE_COMMAND_MANAGER_INL
    #error This file cannot be included directly, include DeviceCommandManager.hpp instead
#endif

#include <aliceVision/depthMap_mtl/Concepts.hpp>

#include <aliceVision/system/Logger.hpp>

namespace aliceVision::depthMap::mtl {

template<MTLPushConstantSafe T>
DeviceCommandManager& DeviceCommandManager::setPushConstants(T data, unsigned long index)
{
    if (!this->_currentCommandEncoder)
        ALICEVISION_THROW_ERROR("Cannot set push constants without an active MTLComputeCommandEncoder!");

    // setBytes only allows data to be up to 4K
    static_assert(sizeof(T) <= 4096, "Push constants must be <= 4096 bytes in Apple Metal!");

    [this->_currentCommandEncoder setBytes:static_cast<const void*>(&data) length:sizeof(T) atIndex:index];

    return *this;
}

template<MTLArrayPushConstantSafe T>
DeviceCommandManager& DeviceCommandManager::setPushConstantsArray(T data, unsigned long index)
{
    if (!this->_currentCommandEncoder)
        ALICEVISION_THROW_ERROR("Cannot set push constants without an active MTLComputeCommandEncoder!");

    // setBytes only allows data to be up to 4K
    static_assert(sizeof(T) <= 4096, "Push constants must be <= 4096 bytes in Apple Metal!");

    [this->_currentCommandEncoder setBytes:static_cast<const void*>(&data) length:sizeof(T) atIndex:index];

    return *this;
}

}  // namespace aliceVision::depthMap::mtl
