// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains all required forward declarations
 *
 * These *must* be used through a std::unique_ptr to ensure ARC compatibility
 */

#pragma once

#include <aliceVision/depthMap_mtl/Concepts.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

namespace aliceVision::depthMap::mtl {

/**
 * @brief An opaque handle to an MTLDevice
 */
struct MTLDeviceImpl;

/**
 * @brief An opaque handle to device memory
 *
 * @tparam T The type of data stored on the device, must comply with the
 *         MTLBufferSafe concept
 * @tparam Dim The number of dimensions this device memory has
 * @tparam MemType The type of memory the buffer should use
 */
template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
struct MTLDeviceMemory;

}  // namespace aliceVision::depthMap::mtl
