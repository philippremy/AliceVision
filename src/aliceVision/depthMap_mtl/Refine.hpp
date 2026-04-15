// This file is part of the AliceVision project.
// Copyright (c) 2017, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/RefineParams.hpp>
#include <aliceVision/depthMap_mtl/Tile.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/mvsData/ROI.hpp>
#include <aliceVision/mvsUtils/MultiViewParams.hpp>
#include <aliceVision/mvsUtils/TileParams.hpp>

#include <string>

namespace aliceVision::depthMap::mtl {

/**
 * @class Depth map estimation refinement
 *
 * @brief Manages the calculation of the Refine step.
 */
class Refine
{
  public:
    /**
     * @brief Refine constructor
     *
     * @param[in] mp The multi-view parameters
     * @param[in] tileParams Tile workflow parameters
     * @param[in] refineParams The Refine parameters
     * @param[in] dev The device to execute on
     */
    Refine(const mvsUtils::MultiViewParams& mp,
           const mvsUtils::TileParams& tileParams,
           const RefineParams& refineParams,
           const std::unique_ptr<MTLDeviceImpl>& dev);

    /* No default constructor */
    Refine() = delete;

    /* No copy/move constructors */
    /* Or yes? */
    Refine(Refine const&) = delete;
    Refine(Refine const&&) = delete;
    Refine operator=(Refine const&) = delete;
    Refine operator=(Refine const&&) = delete;

    /**
     * @brief Get memory consumpyion in device memory.
     *
     * @return device memory consumpyion (in MB)
     */
    double getDeviceMemoryConsumption() const;

    /**
     * @brief Get unpadded memory consumpyion in device memory.
     *
     * @return unpadded device memory consumpyion (in MB)
     */
    double getDeviceMemoryConsumptionUnpadded() const;

    /**
     * @brief Refine for a single R camera the Semi-Global Matching depth/sim map.
     *
     * @param[in] tile The given tile for Refine computation
     * @param[in] in_sgmDepthThicknessMap_dmp The SGM result depth/thickness map in device memory
     * @param[in] in_sgmNormalMap_dmp The SGM result normal map in device memory (or empty)
     */
    void refineRc(const Tile& tile,
                  const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthThicknessMap_dmp,
                  const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_sgmNormalMap_dmp);

    const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& getDeviceDepthSimMap() const;

  private:
    /**
     * @brief Refine and fuse the given depth/sim map using volume strategy.
     *
     * @param[in] tile The given tile for Refine computation
     */
    void refineAndFuseDepthSimMap(const Tile& tile);

    /**
     * @brief Optimize the refined depth/sim maps.
     *
     * @param[in] tile The given tile for Refine computation
     */
    void optimizeDepthSimMap(const Tile& tile);

    /**
     * @brief Compute and write the normal map from the input depth/sim map.
     *
     * @param[in] tile The given tile for Refine computation
     * @param[in] in_depthSimMap_dmp The input depth/sim map in device memory
     * @param[in] name The export filename
     */
    void computeAndWriteNormalMap(const Tile& tile,
                                  const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthSimMap_dmp,
                                  const std::string& name = "");

    /**
     * @brief Export volume cross alembic file and 9 points csv file.
     *
     * @param[in] tile The given tile for Refine computation
     * @param[in] name The export filename
     */
    void exportVolumeInformation(const Tile& tile, const std::string& name) const;

    const mvsUtils::MultiViewParams& _mp;     //< Multi-view parameters
    const mvsUtils::TileParams& _tileParams;  //< tile workflow parameters
    const RefineParams& _refineParams;        //< Refine parameters

    std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>> _sgmDepthPixSizeMap_dmp;    //< rc upscaled SGM depth/pixSize map
    std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>> _refinedDepthSimMap_dmp;    //< rc refined and fused depth/sim map
    std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>> _optimizedDepthSimMap_dmp;  //< rc optimized depth/sim map
    std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>
      _sgmNormalMap_dmp;                                                                 //< rc upscaled SGM normal map (for experimentation purposes)
    std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>> _normalMap_dmp;  //< rc normal map (for debug / intermediate results purposes)
    std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>> _volumeRefineSim_dmp;  //< rc refine similarity volume
    std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>> _optTmpDepthMap_dmp;  //< for color optimization: temporary depth map buffer
    std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>> _optImgVariance_dmp;  //< for color optimization: image variance buffer

    std::unique_ptr<MTLDeviceImpl> _dev;  //< Device to execute on
};

}  // namespace aliceVision::depthMap::mtl
