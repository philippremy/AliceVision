// This file is part of the AliceVision project.
// Copyright (c) 2023, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/NormalMapEstimator.hpp>

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/DepthMapUtils.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceCache.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceDepthSimilarityMap.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>

#include <aliceVision/system/Logger.hpp>
#include <aliceVision/system/Timer.hpp>
#include <aliceVision/utils/filesIO.hpp>
#include <aliceVision/mvsUtils/fileIO.hpp>
#include <aliceVision/mvsUtils/mapIO.hpp>

#include <filesystem>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceImpl.hpp>
#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

namespace fs = std::filesystem;

namespace aliceVision::depthMap::mtl {

NormalMapEstimator::NormalMapEstimator(const mvsUtils::MultiViewParams& mp)
  : _mp(mp)
{}

void NormalMapEstimator::compute(std::unique_ptr<MTLDeviceImpl> dev, const std::vector<int>& cams)
{
    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**dev);
    deviceCache.buildCache(0, 1);  // 0 mipmap image, 1 camera parameters

    for (const int rc : cams)
    {
        const std::string normalMapFilepath = getFileNameFromIndex(_mp, rc, mvsUtils::EFileType::normalMapFiltered);

        if (!utils::exists(normalMapFilepath))
        {
            const system::Timer timer;

            ALICEVISION_LOG_INFO("Compute normal map (RC: " << rc << ")");

            // add R camera parameters to the device cache (device constant memory)
            // no additional downscale applied, we are working at input depth map resolution
            deviceCache.addCameraParams(rc, 1 /*downscale*/, _mp);

            // get R camera parameters id in device constant memory array
            const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(rc, 1 /*downscale*/, _mp);

            // read input depth map
            image::Image<float> in_depthMap;
            mvsUtils::readMap(rc, _mp, mvsUtils::EFileType::depthMapFiltered, in_depthMap);

            // get input depth map width / height
            const int width = in_depthMap.width();
            const int height = in_depthMap.height();

            // default tile parameters, no tiles
            const mvsUtils::TileParams tileParams;

            // fullsize roi
            const ROI roi(0, _mp.getWidth(rc), 0, _mp.getHeight(rc));

            // copy input depth map into depth/sim map in device memory
            // note: we don't need similarity for normal map computation
            //       we use depth/sim map in order to avoid code duplication
            std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>> in_depthSimMap_dmp =
              std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>();
            in_depthSimMap_dmp->associateWithMTLDevice(**dev);
            in_depthSimMap_dmp->allocate2D(MTLResourceSize<2>(size_t(width), size_t(height)));
            {
                std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>> in_depthSimMap_hmh =
                  std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>();
                in_depthSimMap_hmh->associateWithMTLDevice(**dev);
                in_depthSimMap_hmh->allocate2D(in_depthSimMap_dmp->getSize());

                // Copy into host visible buffer
                in_depthSimMap_hmh->writeFromHost([&](std::mdspan<float2, std::dextents<size_t, 2>> contents) {
                    for (int x = 0; x < width; ++x)
                        for (int y = 0; y < height; ++y)
                            contents[x, y] = float2{in_depthMap(y, x), 1.f};
                });

                in_depthSimMap_dmp->copyFromOtherBuffer(*in_depthSimMap_hmh);
            }

            // allocate normal map buffer in device memory
            std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>> out_normalMap_dmp =
              std::make_unique<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>();
            out_normalMap_dmp->associateWithMTLDevice(**dev);
            out_normalMap_dmp->allocate2D(in_depthSimMap_dmp->getSize());

            // compute normal map
            MTL_depthSimMapComputeNormal(out_normalMap_dmp, in_depthSimMap_dmp, rcDeviceCameraParamsId, 1 /*step*/, roi, **dev);

            // write output normal map
            writeNormalMapFiltered(rc, _mp, tileParams, roi, out_normalMap_dmp);

            ALICEVISION_LOG_INFO("Compute normal map (RC: " << rc << ") done in: " << timer.elapsedMs() << " ms.");
        }
    }

    DeviceManager::instance().getDeviceCache(**dev).clearCache();
}

}  // namespace aliceVision::depthMap::mtl
