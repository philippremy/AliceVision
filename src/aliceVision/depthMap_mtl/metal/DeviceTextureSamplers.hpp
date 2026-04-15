// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/Config.h>
#include <aliceVision/depthMap_mtl/Namespace.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

/**
 * Per the CUDA implementation, the type of sampler depends on the underlying
 * data type.
 */
#if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_INTERPOLATION)
    constexpr const sampler TEX_SAMPLER_NONORM(coord::pixel,
                                        address::clamp_to_edge,
                                        filter::linear);
    constexpr const sampler TEX_SAMPLER_NORM(coord::normalized,
                                        address::clamp_to_edge,
                                        filter::linear);
#else
    constexpr const sampler TEX_SAMPLER_NONORM(coord::pixel,
                                        address::clamp_to_edge,
                                        filter::nearest);
    constexpr const sampler TEX_SAMPLER_NORM(coord::normalized,
                                        address::clamp_to_edge,
                                        filter::nearest);
#endif

ALICEVISION_DEPTHMAP_MTL_NS_END
