// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains an interface which allows for tasks that derive
 * IConcurrentDeviceTask to be computed concurrently on multiple devices
 */

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>

#include <memory>
#include <vector>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Interface for multi-GPUs computation.
 */
class IConcurrentDeviceTask
{
  public:
    /**
     * @brief Perform computation for the given list of cameras on multiple
     *        devices concurrently
     *
     * @param[in] cams The list of cameras to perform computation on
     * @param[in,out] task The specialized instance of IConcurrentDeviceTask
     *                     which should be computed
     * @param[in] maxNbDevicesToUse The number of devices to use at maximum
     *                              (0 == all devices available)
     *
     * @throws A runtime exception if any of the sub-tasks threw an exception
     */
    static void concurrentDeviceComputation(const std::vector<int>& cams, IConcurrentDeviceTask& task, unsigned int maxNbDevicesToUse);

  private:
    /**
     * @brief Perform computation for the given list of cameras on the
     *        specified device
     *
     * This method must be specialized (i.e. overridden) by derived classes
     *
     * @param[in] device The Metal device to use for this computation
     * @param[in] cams The list of cameras to perform computation on
     *
     * @throws A runtime exception if an error occurs
     */
    virtual void compute(std::unique_ptr<MTLDeviceImpl> device, const std::vector<int>& cams) = 0;
};

}  // namespace aliceVision::depthMap::mtl
