// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/Config.h>
#include <aliceVision/depthMap_mtl/Namespace.hpp>

/* Metal Headers */
#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

extern constant int d_gaussianArrayOffset[ALICEVISION_DEPTHMAP_MAX_CONSTANT_GAUSS_SCALES];
extern constant float d_gaussianArray[ALICEVISION_DEPTHMAP_MAX_CONSTANT_GAUSS_MEM_SIZE];

inline float getGauss(int scale, int idx) { return d_gaussianArray[d_gaussianArrayOffset[scale] + idx]; };

ALICEVISION_DEPTHMAP_MTL_NS_END
