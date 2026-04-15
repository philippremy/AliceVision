// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains template concepts
 */

#pragma once

#include <type_traits>

namespace aliceVision::depthMap::mtl {

/**
 * @brief A concept for data types which can be safely transferred to a Metal
 *        device through an MTLBuffer
 *
 * @tparam T The type to check conformance for
 */
/* clang-format off */
template<typename T>
concept MTLBufferSafe =
    std::is_trivially_copyable_v<T>
    && std::is_standard_layout_v<T>
    && !std::is_pointer_v<T>
    && !std::is_reference_v<T>
    && !std::is_void_v<T>
    && !std::is_function_v<T>;
/* clang-format on */

/**
 * @brief A concept for data types which can be safely transferred to a Metal
 *        device as a push constant
 *
 * @tparam T The type to check conformance for
 */
/* clang-format off */
template<typename T>
concept MTLPushConstantSafe =
    std::is_trivially_copyable_v<T>
    && std::is_standard_layout_v<T>
    && !std::is_pointer_v<T>
    && !std::is_reference_v<T>
    && !std::is_void_v<T>
    && !std::is_function_v<T>
    && sizeof(T) <= 4096;   /* Push Constants need to be <= 4096 bytes */
/* clang-format on */

/**
 * @brief A concept for data types which can be safely transferred to a Metal
 *        device as a push constant
 *
 * @tparam T The type to check conformance for
 */
/* clang-format off */
template<typename T>
concept MTLArrayPushConstantSafe =
    std::is_trivially_copyable_v<T>
    && std::is_array_v<T>
    && std::is_bounded_array_v<T>
    && std::is_standard_layout_v<T>
    && !std::is_reference_v<T>
    && !std::is_void_v<T>
    && !std::is_function_v<T>
    && sizeof(T) <= 4096;   /* Push Constants need to be <= 4096 bytes */
/* clang-format on */

}  // namespace aliceVision::depthMap::mtl
