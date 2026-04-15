// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/IConcurrentDeviceTask.hpp>

#include <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/system/Logger.hpp>
#include <aliceVision/alicevision_omp.hpp>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceImpl.hpp>

#include <memory>
#include <vector>

namespace aliceVision::depthMap::mtl {

void IConcurrentDeviceTask::concurrentDeviceComputation(const std::vector<int>& cams, IConcurrentDeviceTask& task, unsigned int maxNbDevicesToUse)
{
    // Get the device manager
    DeviceManager& devManager = DeviceManager::instance();

    const unsigned int nbMTLDevices = devManager.mtlDeviceCount();
    const unsigned int nbCPUThreads = static_cast<unsigned int>(omp_get_max_threads());

    ALICEVISION_LOG_INFO("Number of Metal devices: " << nbMTLDevices << ", number of CPU threads: " << nbCPUThreads);

    unsigned int nbThreads = std::min(nbMTLDevices, nbCPUThreads);

    if (maxNbDevicesToUse > 0)
    {
        // Use the user specified limit on the number of GPUs to use
        nbThreads = std::min(nbThreads, maxNbDevicesToUse);
    }

    if (nbThreads == 1)
    {
        // Use the priority device
        task.compute(std::make_unique<MTLDeviceImpl>(devManager.preferredDevice()), cams);
    }
    else
    {
        // backup max threads to keep potentially previously set value
        unsigned int prevThreadCount = static_cast<unsigned int>(omp_get_max_threads());

        // create as many CPU threads as Metal devices that will be used
        omp_set_num_threads(static_cast<int>(nbThreads));

        // Parallelize work with OpenMP
#pragma omp parallel
        {
            const unsigned int cpuThreadId = static_cast<unsigned int>(omp_get_thread_num());
            const unsigned int deviceIdx = cpuThreadId % nbThreads;
            id<MTLDevice> dev = DeviceManager::instance().deviceForIdx(deviceIdx);

            ALICEVISION_LOG_INFO("CPU thread " << cpuThreadId << " (of " << nbThreads << ") uses Metal device: " << [dev registryID]);

            const unsigned int nbCamsPerThread = (cams.size() / nbThreads);
            const unsigned int rcFrom = deviceIdx * nbCamsPerThread;
            unsigned int rcTo = (deviceIdx + 1) * nbCamsPerThread;
            if (deviceIdx == nbThreads - 1)
            {
                rcTo = cams.size();
            }

            std::vector<int> subcams;
            subcams.reserve(cams.size());

            for (unsigned int rc = rcFrom; rc < rcTo; ++rc)
            {
                subcams.push_back(cams[rc]);
            }

            task.compute(std::make_unique<MTLDeviceImpl>(dev), subcams);
        }
        omp_set_num_threads(prevThreadCount);
    }
}

};  // namespace aliceVision::depthMap::mtl
