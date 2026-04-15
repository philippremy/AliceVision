// This file is part of the AliceVision project.
// Copyright (c) 2023, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/DepthMapParams.hpp>
#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/IConcurrentDeviceTask.hpp>
#include <aliceVision/depthMap_mtl/RefineParams.hpp>
#include <aliceVision/depthMap_mtl/SgmParams.hpp>
#include <aliceVision/depthMap_mtl/Tile.hpp>

#include <aliceVision/mvsUtils/MultiViewParams.hpp>
#include <aliceVision/mvsUtils/TileParams.hpp>

#include <memory>
#include <vector>

namespace aliceVision::depthMap::mtl {

/**
 * @class Depth Map Estimator
 *
 * @brief Wraps depth map estimation computation
 * @note Allows muli-device computation (interface IConcurrentDeviceTask)
 */
class DepthMapEstimator final : public IConcurrentDeviceTask
{
  public:
    /**
     * @brief Depth Map Estimator constructor
     *
     * @param[in] mp the multi-view parameters
     * @param[in] tileParams tile workflow parameters
     * @param[in] depthMapParams the depth map estimation parameters
     * @param[in] sgmParams the Semi Global Matching parameters
     * @param[in] refineParams the Refine parameters
     */
    explicit DepthMapEstimator(const mvsUtils::MultiViewParams& mp,
                               const mvsUtils::TileParams& tileParams,
                               const DepthMapParams& depthMapParams,
                               const SgmParams& sgmParams,
                               const RefineParams& refineParams);

    /* No default constructor */
    DepthMapEstimator() = delete;

    /* No copy/move constructors */
    DepthMapEstimator(DepthMapEstimator const&) = delete;
    DepthMapEstimator(DepthMapEstimator const&&) = delete;
    DepthMapEstimator operator=(DepthMapEstimator const&) = delete;
    DepthMapEstimator operator=(DepthMapEstimator const&&) = delete;

  private:
    /**
     * @brief Compute depth/similarity maps for the given cameras.
     *
     * @param[in] device The Metal device to use for this computation
     * @param[in] cams The list of cameras to perform computation on
     *
     * @throws A runtime exception if an error occurs
     */
    void compute(std::unique_ptr<MTLDeviceImpl> device, const std::vector<int>& cams) override;

    /**
     * @brief Compute the maximum number of tiles (volumes, buffer, images, ...)
     *        that fit in GPU memory and can be computed simultaneously.
     *
     * @param[in] dev The device to query
     *
     * @return The number of tiles
     */
    int getNbSimultaneousTiles(const std::unique_ptr<MTLDeviceImpl>& dev) const;

    /**
     * @brief Build tile list from the given cameras
     *
     * @param[in] cams The list of cameras
     * @param[in,out] tiles The output tile list
     */
    void getTilesList(const std::vector<int>& cams, std::vector<Tile>& tiles) const;

    const mvsUtils::MultiViewParams& _mp;     //< multi-view parameters
    const mvsUtils::TileParams& _tileParams;  //< tiling parameters
    const DepthMapParams& _depthMapParams;    //< depth map estimation parameters
    const SgmParams& _sgmParams;              //< parameters of Sgm process
    const RefineParams& _refineParams;        //< parameters of Refine process
    std::vector<ROI> _tileRoiList;            //< depth maps region-of-interest list
};

}  // namespace aliceVision::depthMap::mtl
