// This file is part of the AliceVision project.
// Copyright (c) 2022, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains various utility functions for working with DepthMaps
 */

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/SgmParams.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/mvsData/ROI.hpp>
#include <aliceVision/mvsUtils/MultiViewParams.hpp>
#include <aliceVision/mvsUtils/TileParams.hpp>

#include <memory>
#include <string>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Write a depth/similarity map on disk from device memory
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] tileParams Tile workflow parameters
 * @param[in] roi The 2D region of interest without any downscale apply
 * @param[in] in_depthSimMap_dmp The depth/similarity map in device memory
 * @param[in] scale The depth/similarity map downscale factor
 * @param[in] step The depth/similarity map step factor
 * @param[in] name The export filename suffix
 */
void writeDepthSimMap(int rc,
                      const mvsUtils::MultiViewParams& mp,
                      const mvsUtils::TileParams& tileParams,
                      const ROI& roi,
                      const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthSimMap_dmp,
                      int scale,
                      int step,
                      const std::string& name = "");

/**
 * @brief Write a normal map (depth map estimation) on disk from device memory
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] tileParams Tile workflow parameters
 * @param[in] roi The 2D region of interest without any downscale apply
 * @param[in] in_normalMap_dmp The normal map in device memory
 * @param[in] scale The map downscale factor
 * @param[in] step The map step factor
 * @param[in] name The export filename suffix
 */
void writeNormalMap(int rc,
                    const mvsUtils::MultiViewParams& mp,
                    const mvsUtils::TileParams& tileParams,
                    const ROI& roi,
                    const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_normalMap_dmp,
                    int scale,
                    int step,
                    const std::string& name = "");

/**
 * @brief Reset a depth/similarity map in host memory to the given default
 *        depth and similarity
 *
 * @param[in,out] inout_depthSimMap_hmh The depth/similarity map in host memory
 * @param[in] depth The depth reset value
 * @param[in] sim The sim reset value
 */
void resetDepthSimMap(std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>& inout_depthSimMap_hmh,
                      float depth = -1.f,
                      float sim = 1.f);

/**
 * @brief Write a depth/similarity map on disk from a tile list in host memory
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] tileParams Tile workflow parameters
 * @param[in] tileRoiList The 2d region of interest of each tile
 * @param[in] in_depthSimMapTiles_hmh The depth/similarity map tile list in
 *            host memory
 * @param[in] scale The depth/similarity map downscale factor
 * @param[in] step The depth/similarity map step factor
 * @param[in] name The export filename suffix
 */
void writeDepthSimMapFromTileList(int rc,
                                  const mvsUtils::MultiViewParams& mp,
                                  const mvsUtils::TileParams& tileParams,
                                  const std::vector<ROI>& tileRoiList,
                                  const std::vector<std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>>& in_depthSimMapTiles_hmh,
                                  int scale,
                                  int step,
                                  const std::string& name = "");

/**
 * @brief Build and write a debug OBJ file with all tiles areas
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] tileRoiList Tile region-of-interest list
 * @param[in] tileMinMaxDepthsList Tile min/max depth list
 */
void exportDepthSimMapTilePatternObj(int rc,
                                     const mvsUtils::MultiViewParams& mp,
                                     const std::vector<ROI>& tileRoiList,
                                     const std::vector<std::pair<float, float>>& tileMinMaxDepthsList);

/**
 * @brief Merge depth/similarity map tiles on disk
 *
 * @param[in] rc the related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] scale The depth/similarity map downscale factor
 * @param[in] step The depth/similarity map step factor
 * @param[in] name The export filename suffix
 */
void mergeDepthSimMapTiles(int rc, const mvsUtils::MultiViewParams& mp, int scale, int step, const std::string& name = "");

/**
 * @brief Merge normal map tiles on disk
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] scale The normal map downscale factor
 * @param[in] step The normal map step factor
 * @param[in] name The export filename suffix
 */
void mergeNormalMapTiles(int rc, const mvsUtils::MultiViewParams& mp, int scale, int step, const std::string& name = "");

/**
 * @brief Merge depth/pixSize map tiles on disk
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] scale The depth/pixSize map downscale factor
 * @param[in] step The depth/pixSize map step factor
 * @param[in] name The export filename suffix
 */
void mergeDepthPixSizeMapTiles(int rc, const mvsUtils::MultiViewParams& mp, int scale, int step, const std::string& name = "");

/**
 * @brief Write a depth/pixSize map on disk from device memory
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] tileParams Tile workflow parameters
 * @param[in] roi The 2D region of interest without any downscale apply
 * @param[in] in_depthPixSize_dmp The depth/pixSize map in device memory
 * @param[in] scale The depth/pixSize map downscale factor
 * @param[in] step The depth/pixSize map step factor
 * @param[in] name The export filename suffix
 */
void writeDepthPixSizeMap(int rc,
                          const mvsUtils::MultiViewParams& mp,
                          const mvsUtils::TileParams& tileParams,
                          const ROI& roi,
                          const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthPixSize_dmp,
                          int scale,
                          int step,
                          const std::string& name = "");

/**
 * @brief Write a normal map (depth map filtering) on disk from device memory
 *
 * @param[in] rc The related R camera index
 * @param[in] mp The multi-view parameters
 * @param[in] tileParams Tile workflow parameters
 * @param[in] roi The 2D region of interest without any downscale apply
 * @param[in] in_normalMap_dmp The normal map in device memory
 * @param[in] scale The map downscale factor
 * @param[in] step The map step factor
 * @param[in] name The export filename suffix
 */
void writeNormalMapFiltered(int rc,
                            const mvsUtils::MultiViewParams& mp,
                            const mvsUtils::TileParams& tileParams,
                            const ROI& roi,
                            const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_normalMap_dmp,
                            int scale = 1,
                            int step = 1,
                            const std::string& name = "");

}  // namespace aliceVision::depthMap::mtl
