// This file is part of the AliceVision project.
// Copyright (c) 2023, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/depthMap_mtl/IConcurrentDeviceTask.hpp>

#include <aliceVision/mvsUtils/MultiViewParams.hpp>

#include <memory>
#include <vector>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Normal Map Estimator
 *
 * @brief Wraps normal map estimation computation
 * @note Allows muli-device computation (interface IConcurrentDeviceTask)
 */
class NormalMapEstimator final : public IConcurrentDeviceTask
{
  public:
    /**
     * @brief Normal Map Estimator constructor
     *
     * @param[in] mp the multi-view parameters
     */
    explicit NormalMapEstimator(const mvsUtils::MultiViewParams& mp);

    /* No default constructor */
    NormalMapEstimator() = delete;

    /* No copy/move constructors */
    NormalMapEstimator(NormalMapEstimator const&) = delete;
    NormalMapEstimator(NormalMapEstimator const&&) = delete;
    NormalMapEstimator operator=(NormalMapEstimator const&) = delete;
    NormalMapEstimator operator=(NormalMapEstimator const&&) = delete;

  private:
    /**
     * @brief Compute normal maps of the given cameras
     *
     * @param[in] device The Metal device to use for this computation
     * @param[in] cams The list of cameras to perform computation on
     *
     * @throws A runtime exception if an error occurs
     */
    void compute(std::unique_ptr<MTLDeviceImpl> device, const std::vector<int>& cams) override;

    const mvsUtils::MultiViewParams& _mp;  //< Multi-view parameters
};

}  // namespace aliceVision::depthMap::mtl
