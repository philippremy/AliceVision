// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file currently handles the configuration of the DepthMap library with
 * the Apple Metal backend
 */

#pragma once

/* Use unsigned char for DepthMaps */
// #define ALICEVISION_DEPTHMAP_TEXTURE_USE_UCHAR

/* Use a 16-bit floating point type for DepthMaps */
#define ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF

/* Use a 32-bit floating point type for DepthMaps */
// #define ALICEVISION_DEPTHMAP_TEXTURE_USE_FLOAT

/* Use unsigned char for the similarity values in a volume */
#define ALICEVISION_DEPTHMAP_TSIM_USE_UCHAR

/* Use a 32-bit floating point type for the similarity values in a volume */
// #define ALICEVISION_DEPTHMAP_TSIM_USE_FLOAT

/* Use a 16-bit floating point type for the similarity values in refinement */
#define ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_HALF

/* Use a 32-bit floating point type for the similarity values in refinement */
// #define ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_FLOAT

/* Use interpolation for DepthMaps */
#define ALICEVISION_DEPTHMAP_TEXTURE_USE_INTERPOLATION

/* The maximum number of camera paramter sets to use */
#define ALICEVISION_DEVICE_MAX_CONSTANT_CAMERA_PARAM_SETS 128

/* The maximum number of subparts in a custom patch pattern */
/* Note: each patch pattern subpart gives one similarity */
#define ALICEVISION_DEVICE_PATCH_MAX_SUBPARTS 4

/* The maximum number of coordinates per patch pattern subpart */
#define ALICEVISION_DEVICE_PATCH_MAX_COORDS_PER_SUBPARTS 24

/* The maximum number of scales to generate a gaussian filter for */
#define ALICEVISION_DEPTHMAP_MAX_CONSTANT_GAUSS_SCALES 10

/* The maximum number of gaussian values */
#define ALICEVISION_DEPTHMAP_MAX_CONSTANT_GAUSS_MEM_SIZE 128

/* The maximum downscale which can be used */
#define DEVICE_MAX_DOWNSCALE (MAX_CONSTANT_GAUSS_SCALES - 1)
