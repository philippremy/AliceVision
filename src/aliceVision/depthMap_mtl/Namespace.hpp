// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file currently helps switching between the namespace definitions for
 * C++ (which can be nested) and MSL (which cannot be nested, because MSL 3.2
 * is based on C++14).
 *
 * Only use in headers which are shared between C++/Objective-C++/MSL!
 */

#pragma once

#if defined(__METAL__)
#define ALICEVISION_DEPTHMAP_MTL_NS_START \
namespace aliceVision { \
namespace depthMap { \
namespace mtl {
#define ALICEVISION_DEPTHMAP_MTL_NS_END \
} \
} \
}
#elif defined(__cplusplus) && !defined(__METAL__)
#define ALICEVISION_DEPTHMAP_MTL_NS_START namespace aliceVision::depthMap::mtl {
#define ALICEVISION_DEPTHMAP_MTL_NS_END }
#endif