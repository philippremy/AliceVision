// This file is part of the AliceVision project.
// Copyright (c) 2017, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/Tile.hpp>
#include <aliceVision/depthMap_mtl/RefineParams.hpp>
#include <aliceVision/depthMap_mtl/SgmDepthList.hpp>
#include <aliceVision/depthMap_mtl/SgmParams.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/mvsData/ROI.hpp>
#include <aliceVision/mvsUtils/MultiViewParams.hpp>
#include <aliceVision/mvsUtils/TileParams.hpp>

#include <memory>
#include <string>

namespace aliceVision::depthMap::mtl {

/**
 * @class Depth map estimation Semi-Global Matching
 *
 * @brief Manages the calculation of the Semi-Global Matching step.
 */
class Sgm
{
  public:
    /**
     * @brief Sgm constructor
     *
     * @param[in] mp The multi-view parameters
     * @param[in] tileParams Tile workflow parameters
     * @param[in] sgmParams The Semi Global Matching parameters
     * @param[in] computeDepthSimMap Enable final depth/sim map computation
     * @param[in] computeNormalMap Enable final normal map computation
     * @param[in] dev The device to execute on
     */
    Sgm(const mvsUtils::MultiViewParams& mp,
        const mvsUtils::TileParams& tileParams,
        const SgmParams& sgmParams,
        bool computeDepthSimMap,
        bool computeNormalMap,
        const std::unique_ptr<MTLDeviceImpl>& dev);

    /* No default constructor */
    Sgm() = delete;

    /* No copy/move constructors */
    /* Or yes? */
    Sgm(Sgm const&) = delete;
    Sgm(Sgm const&&) = delete;
    Sgm operator=(Sgm const&) = delete;
    Sgm operator=(Sgm const&&) = delete;

    /**
     * @brief Get memory consumpyion in device memory.
     *
     * @return Device memory consumption (in MB)
     */
    double getDeviceMemoryConsumption() const;

    /**
     * @brief Get unpadded memory consumpyion in device memory.
     *
     * @return Unpadded device memory consumption (in MB)
     */
    double getDeviceMemoryConsumptionUnpadded() const;

    /**
     * @brief Compute for a single R camera the Semi-Global Matching.
     *
     * @param[in] tile The given tile for SGM computation
     * @param[in] tileDepthList the tile SGM depth list
     */
    void sgmRc(const Tile& tile, const SgmDepthList& tileDepthList);

    /**
     * @brief Smooth SGM result thickness map
     *
     * @note Important to be a proper Refine input parameter.
     *
     * @param[in] tile The given tile for SGM computation
     * @param[in] refineParams the Refine parameters
     */
    void smoothThicknessMap(const Tile& tile, const RefineParams& refineParams);

    const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& getDeviceDepthThicknessMap() const;

    const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& getDeviceDepthSimMap() const;

    const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& getDeviceNormalMap() const;

  private:
    /**
     * @brief Compute for each RcTc the best / second best similarity volumes.
     *
     * @param[in] tile The given tile for SGM computation
     * @param[in] tileDepthList the tile SGM depth list
     */
    void computeSimilarityVolumes(const Tile& tile, const SgmDepthList& tileDepthList);

    /**
     * @brief Optimize the given similarity volume.
     *
     * @note  Filter on the 3D volume to weight voxels based on their neighborhood strongness.
     *        So it downweights local minimums that are not supported by their neighborhood.
     *
     * @param[in] tile The given tile for SGM computation
     * @param[in] tileDepthList the tile SGM depth list
     */
    void optimizeSimilarityVolume(const Tile& tile, const SgmDepthList& tileDepthList);

    /**
     * @brief Retrieve the best depths in the given similarity volume.
     *
     * @note  For each pixel, choose the voxel with the minimal similarity value.
     *
     * @param[in] tile The given tile for SGM computation
     * @param[in] tileDepthList the tile SGM depth list
     */
    void retrieveBestDepth(const Tile& tile, const SgmDepthList& tileDepthList);

    /**
     * @brief Export volume alembic files and 9 points csv file.
     *
     * @param[in] tile The given tile for SGM computation
     * @param[in] tileDepthList the tile SGM depth list
     * @param[in] in_volume_dmp the input volume
     * @param[in] name the export filename
     */
    void exportVolumeInformation(const Tile& tile,
                                 const SgmDepthList& tileDepthList,
                                 const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volume_dmp,
                                 const std::string& name) const;

    const mvsUtils::MultiViewParams& _mp;     //< Multi-view parameters
    const mvsUtils::TileParams& _tileParams;  //< tile workflow parameters
    const SgmParams& _sgmParams;              //< Semi Global Matching parameters
    const bool _computeDepthSimMap;           //< needs to compute a final depth/sim map
    const bool _computeNormalMap;             //< needs to compute a final normal map

    // MAYBE NOT REQUIRED? CudaHostMemoryHeap<float, 2> _depths_hmh;                   //< rc depth data host memory
    // ^^^^^^^^^^^^^^^^^^^ Must be created in constructor, this acts as a staging buffer so we can maybe avoid it

    std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::HostVisible>> _depths_hmh;             //< rc depth data host visible memory
    std::unique_ptr<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>> _depths_dmp;              //< rc depth data device memory
    std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>> _depthThicknessMap_dmp;  //< rc result depth thickness map
    std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>> _depthSimMap_dmp;        //< rc result depth/sim map
    std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>> _normalMap_dmp;          //< rc normal map
    std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>> _volumeBestSim_dmp;        //< rc best similarity volume
    std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>> _volumeSecBestSim_dmp;     //< rc second best similarity volume
    std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>> _volumeSliceAccA_dmp;   //< for optimization: volume accumulation slice A
    std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>> _volumeSliceAccB_dmp;   //< for optimization: volume accumulation slice B
    std::unique_ptr<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>> _volumeAxisAcc_dmp;     //< for optimization: volume accumulation axis

    std::unique_ptr<MTLDeviceImpl> _dev;  //< Device to execute on
};

}  // namespace aliceVision::depthMap::mtl
