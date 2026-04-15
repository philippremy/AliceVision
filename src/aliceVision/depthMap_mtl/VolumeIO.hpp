// This file is part of the AliceVision project.
// Copyright (c) 2022, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains various utility functions for working with volume I/O
 */

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/RefineParams.hpp>
#include <aliceVision/depthMap_mtl/SgmParams.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/mvsData/ROI.hpp>
#include <aliceVision/mvsUtils/MultiViewParams.hpp>

#include <memory>
#include <string>
#include <vector>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Export the given similarity volume to an Alembic file
 *
 * @param[in] in_volumeSim_hmh The similarity in host memory
 * @param[in] in_depths The SGM depth list
 * @param[in] mp The multi-view parameters
 * @param[in] camIndex The R cam global index
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] filepath The export filepath
 * @param[in] roi The 2D region of interest
 */
void exportSimilarityVolume(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                            const std::vector<float>& in_depths,
                            const mvsUtils::MultiViewParams& mp,
                            int camIndex,
                            const SgmParams& sgmParams,
                            const std::string& filepath,
                            const ROI& roi);

/**
 * @brief Export a cross of the given similarity volume to an Alembic file
 *
 * @param[in] in_volumeSim_hmh The similarity in host memory
 * @param[in] in_depths The SGM depth list
 * @param[in] mp The multi-view parameters
 * @param[in] camIndex The R cam global index
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] filepath The export filepath
 * @param[in] roi The 2D region of interest
 */
void exportSimilarityVolumeCross(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                 const std::vector<float>& in_depths,
                                 const mvsUtils::MultiViewParams& mp,
                                 int camIndex,
                                 const SgmParams& sgmParams,
                                 const std::string& filepath,
                                 const ROI& roi);

/**
 * @brief Export a cross of the given similarity volume to an Alembic file
 *
 * @param[in] in_volumeSim_hmh The similarity in host memory
 * @param[in] in_depths The SGM depth list
 * @param[in] mp The multi-view parameters
 * @param[in] camIndex The R cam global index
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] filepath The export filepath
 * @param[in] roi The 2D region of interest
 */
void exportSimilarityVolumeCross(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                 const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>& in_depthSimMapSgmUpscale_hmh,
                                 const mvsUtils::MultiViewParams& mp,
                                 int camIndex,
                                 const RefineParams& refineParams,
                                 const std::string& filepath,
                                 const ROI& roi);

/**
 * @brief Export a topographic cut of the given similarity volume to an Alembic file
 *
 * @param[in] in_volumeSim_hmh The similarity in host memory
 * @param[in] in_depths The SGM depth list
 * @param[in] mp The multi-view parameters
 * @param[in] camIndex The R cam global index
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] filepath The export filepath
 * @param[in] roi The 2D region of interest
 */
void exportSimilarityVolumeTopographicCut(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                          const std::vector<float>& in_depths,
                                          const mvsUtils::MultiViewParams& mp,
                                          int camIndex,
                                          const SgmParams& sgmParams,
                                          const std::string& filepath,
                                          const ROI& roi);

/**
 * @brief Export 9 similarity values over the entire depth in a CSV file
 *
 * @param[in] in_volumeSim_hmh The similarity in host memory
 * @param[in] in_depths The SGM depth list
 * @param[in] name The export name
 * @param[in] sgmParams The Semi Global Matching parameters
 * @param[in] filepath The export filepath
 * @param[in] roi The 2D region of interest
 */
void exportSimilaritySamplesCSV(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                const std::vector<float>& in_depths,
                                const std::string& name,
                                const SgmParams& sgmParams,
                                const std::string& filepath,
                                const ROI& roi);

/**
 * @brief Export a topographic cut of the given similarity volume to an Alembic
 *        file
 *
 * @param[in] in_volumeSim_hmh The similarity in host memory
 * @param[in] in_depthSimMapSgmUpscale_hmh The upscaled SGM depth/sim map
 * @param[in] mp The multi-view parameters
 * @param[in] camIndex The R cam global index
 * @param[in] refineParams The Refine parameters
 * @param[in] filepath The export filepath
 * @param[in] roi The 2D region of interest
 */
void exportSimilarityVolumeTopographicCut(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                          const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>& in_depthSimMapSgmUpscale_hmh,
                                          const mvsUtils::MultiViewParams& mp,
                                          int camIndex,
                                          const RefineParams& refineParams,
                                          const std::string& filepath,
                                          const ROI& roi);

/**
 * @brief Export 9 similarity values over the entire depth in a CSV file
 *
 * @param[in] in_volumeSim_hmh The similarity in host memory
 * @param[in] name The export name
 * @param[in] refineParams The Refine parameters
 * @param[in] filepath The export filepath
 * @param[in] roi The 2D region of interest
 */
void exportSimilaritySamplesCSV(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                const std::string& name,
                                const RefineParams& refineParams,
                                const std::string& filepath,
                                const ROI& roi);

}  // namespace aliceVision::depthMap::mtl
