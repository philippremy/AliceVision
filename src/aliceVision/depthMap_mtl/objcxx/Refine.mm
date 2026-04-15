// This file is part of the AliceVision project.
// Copyright (c) 2017, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Refine.hpp>

#include <aliceVision/depthMap_mtl/DepthMapUtils.hpp>
#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>
#include <aliceVision/depthMap_mtl/VolumeIO.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceCache.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceDepthSimilarityMap.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceSimilarityVolume.hpp>

#include <aliceVision/mvsUtils/fileIO.hpp>
#include <aliceVision/numeric/numeric.hpp>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceImpl.hpp>
#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

namespace aliceVision::depthMap::mtl {

Refine::Refine(const mvsUtils::MultiViewParams& mp,
               const mvsUtils::TileParams& tileParams,
               const RefineParams& refineParams,
               const std::unique_ptr<MTLDeviceImpl>& dev)
  : _mp(mp),
    _tileParams(tileParams),
    _refineParams(refineParams),
    _dev(std::make_unique<MTLDeviceImpl>(*dev))
{
    this->_sgmDepthPixSizeMap_dmp = std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>();
    this->_refinedDepthSimMap_dmp = std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>();
    this->_optimizedDepthSimMap_dmp = std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>();
    this->_sgmNormalMap_dmp = std::make_unique<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>();
    this->_normalMap_dmp = std::make_unique<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>();
    this->_volumeRefineSim_dmp = std::make_unique<MTLDeviceMemory<TSimRefine, 3, MemoryType::DeviceOnly>>();
    this->_optTmpDepthMap_dmp = std::make_unique<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>();
    this->_optImgVariance_dmp = std::make_unique<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>();

    this->_sgmDepthPixSizeMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_refinedDepthSimMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_optimizedDepthSimMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_sgmNormalMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_normalMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_volumeRefineSim_dmp->associateWithMTLDevice(**this->_dev);
    this->_optTmpDepthMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_optImgVariance_dmp->associateWithMTLDevice(**this->_dev);

    // get tile maximum dimensions
    const int downscale = _refineParams.scale * _refineParams.stepXY;
    const int maxTileWidth = divideRoundUp(tileParams.bufferWidth, downscale);
    const int maxTileHeight = divideRoundUp(tileParams.bufferHeight, downscale);

    // compute depth/sim map maximum dimensions
    const MTLResourceSize<2> depthSimMapDim(maxTileWidth, maxTileHeight);

    // allocate depth/sim maps in device memory
    _sgmDepthPixSizeMap_dmp->allocate2D(depthSimMapDim);
    _refinedDepthSimMap_dmp->allocate2D(depthSimMapDim);
    _optimizedDepthSimMap_dmp->allocate2D(depthSimMapDim);

    // allocate SGM upscaled normal map in device memory
    if (_refineParams.useSgmNormalMap)
        _sgmNormalMap_dmp->allocate2D(depthSimMapDim);

    // allocate normal map in device memory
    if (_refineParams.exportIntermediateNormalMaps)
        _normalMap_dmp->allocate2D(depthSimMapDim);

    // compute volume maximum dimensions
    const int nbDepthsToRefine = _refineParams.halfNbDepths * 2 + 1;
    const MTLResourceSize<3> volDim(maxTileWidth, maxTileHeight, nbDepthsToRefine);

    // allocate refine volume in device memory
    _volumeRefineSim_dmp->allocate3D(volDim);

    // allocate depth/sim map optimization buffers
    if (_refineParams.useColorOptimization)
    {
        _optTmpDepthMap_dmp->allocate2D(depthSimMapDim);
        _optImgVariance_dmp->allocate2D(depthSimMapDim);
    }
}

double Refine::getDeviceMemoryConsumption() const
{
    size_t bytes = 0;

    bytes += _sgmDepthPixSizeMap_dmp->getAllocationSize();
    bytes += _refinedDepthSimMap_dmp->getAllocationSize();
    bytes += _optimizedDepthSimMap_dmp->getAllocationSize();
    bytes += _sgmNormalMap_dmp->getAllocationSize();
    bytes += _normalMap_dmp->getAllocationSize();
    bytes += _volumeRefineSim_dmp->getAllocationSize();
    bytes += _optTmpDepthMap_dmp->getAllocationSize();
    bytes += _optImgVariance_dmp->getAllocationSize();

    return (double(bytes) / (1024.0 * 1024.0));
}

double Refine::getDeviceMemoryConsumptionUnpadded() const
{
    // Metal does not insert padding!
    return this->getDeviceMemoryConsumption();
}

const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& Refine::getDeviceDepthSimMap() const
{ return this->_optimizedDepthSimMap_dmp; }

void Refine::refineRc(const Tile& tile,
                      const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_sgmDepthThicknessMap_dmp,
                      const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& in_sgmNormalMap_dmp)
{
    const IndexT viewId = _mp.getViewId(tile.rc);

    ALICEVISION_LOG_INFO(tile << "Refine depth/sim map of view ID: " << viewId << ", RC: " << tile.rc << " (" << (tile.rc + 1) << " / " << _mp.ncams
                              << ").");

    // compute upscaled SGM depth/pixSize map
    // compute upscaled SGM normal map
    {
        // downscale the region of interest
        const ROI downscaledRoi = downscaleROI(tile.roi, _refineParams.scale * _refineParams.stepXY);

        // get device cache instance
        DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);

        // get R device camera parameters id from cache
        const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tile.rc, _refineParams.scale, _mp);

        // get R device mipmap image from cache
        const DeviceMipmapImage& rcDeviceMipmapImage = deviceCache.requestMipmapImage(tile.rc, _mp);

        // compute upscaled SGM depth/pixSize map
        // - upscale SGM depth/thickness map
        // - filter masked pixels (alpha)
        // - compute pixSize from SGM thickness
        MTL_computeSgmUpscaledDepthPixSizeMap(this->_sgmDepthPixSizeMap_dmp,
                                              in_sgmDepthThicknessMap_dmp,
                                              rcDeviceCameraParamsId,
                                              rcDeviceMipmapImage,
                                              this->_refineParams,
                                              downscaledRoi,
                                              **this->_dev);

        // export intermediate depth/pixSize map (if requested by user)
        if (_refineParams.exportIntermediateDepthSimMaps)
            writeDepthPixSizeMap(
              tile.rc, _mp, _tileParams, tile.roi, _sgmDepthPixSizeMap_dmp, _refineParams.scale, _refineParams.stepXY, "sgmUpscaled");

        // upscale SGM normal map (if needed)
        if (_refineParams.useSgmNormalMap && in_sgmNormalMap_dmp->getAllocationSize() != 0)
        {
            MTL_normalMapUpscale(this->_sgmNormalMap_dmp, in_sgmNormalMap_dmp, downscaledRoi, **this->_dev);
        }
    }

    // refine and fuse depth/sim map
    if (_refineParams.useRefineFuse)
    {
        // refine and fuse with volume strategy
        refineAndFuseDepthSimMap(tile);
    }
    else
    {
        ALICEVISION_LOG_INFO(tile << "Refine and fuse depth/sim map volume disabled.");
        MTL_depthSimMapCopyDepthOnly(this->_refinedDepthSimMap_dmp, this->_sgmDepthPixSizeMap_dmp, 1.0f, **this->_dev);
    }

    // export intermediate depth/sim map (if requested by user)
    if (_refineParams.exportIntermediateDepthSimMaps)
        writeDepthSimMap(tile.rc, _mp, _tileParams, tile.roi, _refinedDepthSimMap_dmp, _refineParams.scale, _refineParams.stepXY, "refinedFused");

    // export intermediate normal map (if requested by user)
    if (_refineParams.exportIntermediateNormalMaps)
        computeAndWriteNormalMap(tile, _refinedDepthSimMap_dmp, "refinedFused");

    // optimize depth/sim map
    if (_refineParams.useColorOptimization && _refineParams.optimizationNbIterations > 0)
    {
        optimizeDepthSimMap(tile);
    }
    else
    {
        ALICEVISION_LOG_INFO(tile << "Color optimize depth/sim map disabled.");
        _optimizedDepthSimMap_dmp->copyFromOtherBuffer(*_refinedDepthSimMap_dmp);
    }

    // export intermediate normal map (if requested by user)
    if (_refineParams.exportIntermediateNormalMaps)
        computeAndWriteNormalMap(tile, _optimizedDepthSimMap_dmp);

    ALICEVISION_LOG_INFO(tile << "Refine depth/sim map done.");
}

void Refine::refineAndFuseDepthSimMap(const Tile& tile)
{
    ALICEVISION_LOG_INFO(tile << "Refine and fuse depth/sim map volume.");

    // downscale the region of interest
    const ROI downscaledRoi = downscaleROI(tile.roi, _refineParams.scale * _refineParams.stepXY);

    // get the depth range
    const Range depthRange(0, _volumeRefineSim_dmp->getSize().depth());

    // initialize the similarity volume at 0
    // each tc filtered and inverted similarity value will be summed in this volume
    MTL_volumeInitTSimRefine(this->_volumeRefineSim_dmp, TSimRefine(0.f), **this->_dev);

    // get device cache instance
    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);

    // get R device camera parameters id from cache
    const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tile.rc, _refineParams.scale, _mp);

    // get R device mipmap image from cache
    const DeviceMipmapImage& rcDeviceMipmapImage = deviceCache.requestMipmapImage(tile.rc, _mp);

    // compute for each RcTc each similarity value for each depth to refine
    // sum the inverted / filtered similarity value, best value is the HIGHEST
    for (std::size_t tci = 0; tci < tile.refineTCams.size(); ++tci)
    {
        const int tc = tile.refineTCams.at(tci);

        // get T device camera parameters id from cache
        const int tcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tc, _refineParams.scale, _mp);

        // get T device mipmap image from cache
        const DeviceMipmapImage& tcDeviceMipmapImage = deviceCache.requestMipmapImage(tc, _mp);

        ALICEVISION_LOG_DEBUG(tile << "Refine similarity volume:" << std::endl
                                   << "\t- RC: " << tile.rc << std::endl
                                   << "\t- TC: " << tc << " (" << (tci + 1) << "/" << tile.refineTCams.size() << ")" << std::endl
                                   << "\t- RC camera parameters id: " << rcDeviceCameraParamsId << std::endl
                                   << "\t- TC camera parameters id: " << tcDeviceCameraParamsId << std::endl
                                   << "\t- Tile range x: [" << downscaledRoi.x.begin << " - " << downscaledRoi.x.end << "]" << std::endl
                                   << "\t- Tile range y: [" << downscaledRoi.y.begin << " - " << downscaledRoi.y.end << "]" << std::endl);

        MTL_volumeRefineSimilarity(this->_volumeRefineSim_dmp,
                                   this->_sgmDepthPixSizeMap_dmp,
                                   this->_sgmNormalMap_dmp,
                                   this->_refineParams.useSgmNormalMap,
                                   rcDeviceCameraParamsId,
                                   tcDeviceCameraParamsId,
                                   rcDeviceMipmapImage,
                                   tcDeviceMipmapImage,
                                   this->_refineParams,
                                   depthRange,
                                   downscaledRoi,
                                   **this->_dev);
    }

    // export intermediate volume information (if requested by user)
    exportVolumeInformation(tile, "afterRefine");

    // retrieve the best depth/sim in the volume
    // compute sub-pixel sample using a sliding gaussian
    MTL_volumeRefineBestDepth(
      this->_refinedDepthSimMap_dmp, this->_sgmDepthPixSizeMap_dmp, this->_volumeRefineSim_dmp, this->_refineParams, downscaledRoi, **this->_dev);

    ALICEVISION_LOG_INFO(tile << "Refine and fuse depth/sim map volume done.");
}

void Refine::optimizeDepthSimMap(const Tile& tile)
{
    ALICEVISION_LOG_INFO(tile << "Color optimize depth/sim map.");

    // downscale the region of interest
    const ROI downscaledRoi = downscaleROI(tile.roi, _refineParams.scale * _refineParams.stepXY);

    // get R device camera from cache
    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);

    // get R device camera parameters id from cache
    const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tile.rc, _refineParams.scale, _mp);

    // get R device mipmap image from cache
    const DeviceMipmapImage& rcDeviceMipmapImage = deviceCache.requestMipmapImage(tile.rc, _mp);

    MTL_depthSimMapOptimizeGradientDescent(this->_optimizedDepthSimMap_dmp,  // output depth/sim map optimized
                                           this->_optImgVariance_dmp,        // image variance buffer pre-allocate
                                           this->_optTmpDepthMap_dmp,        // temporary depth map buffer pre-allocate
                                           this->_sgmDepthPixSizeMap_dmp,    // input SGM upscaled depth/pixSize map
                                           this->_refinedDepthSimMap_dmp,    // input refined and fused depth/sim map
                                           rcDeviceCameraParamsId,
                                           rcDeviceMipmapImage,
                                           this->_refineParams,
                                           downscaledRoi,
                                           **this->_dev);

    ALICEVISION_LOG_INFO(tile << "Color optimize depth/sim map done.");
}

void Refine::computeAndWriteNormalMap(const Tile& tile,
                                      const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& in_depthSimMap_dmp,
                                      const std::string& name)
{
    // downscale the region of interest
    const ROI downscaledRoi = downscaleROI(tile.roi, _refineParams.scale * _refineParams.stepXY);

    // get R device camera parameters id from cache
    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);
    const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tile.rc, _refineParams.scale, _mp);

    ALICEVISION_LOG_INFO(tile << "Refine compute normal map of view id: " << _mp.getViewId(tile.rc) << ", rc: " << tile.rc << " (" << (tile.rc + 1)
                              << " / " << _mp.ncams << ").");

    MTL_depthSimMapComputeNormal(_normalMap_dmp, in_depthSimMap_dmp, rcDeviceCameraParamsId, _refineParams.stepXY, downscaledRoi, **this->_dev);

    writeNormalMap(tile.rc, _mp, _tileParams, tile.roi, _normalMap_dmp, _refineParams.scale, _refineParams.stepXY, name);
}

void Refine::exportVolumeInformation(const Tile& tile, const std::string& name) const
{
    if (!_refineParams.exportIntermediateCrossVolumes && !_refineParams.exportIntermediateVolume9pCsv)
    {
        // nothing to do
        return;
    }

    // get tile begin indexes (default no tile)
    int tileBeginX = -1;
    int tileBeginY = -1;

    if (tile.nbTiles > 1)
    {
        tileBeginX = tile.roi.x.begin;
        tileBeginY = tile.roi.y.begin;
    }

    // copy device similarity volume to host memory
    std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>> volumeSim_hmh =
      std::make_unique<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>>();
    volumeSim_hmh->associateWithMTLDevice(**this->_dev);
    volumeSim_hmh->allocate3D(_volumeRefineSim_dmp->getSize());
    volumeSim_hmh->copyFromOtherBuffer(*_volumeRefineSim_dmp);

    // copy device SGM upscale depth/sim map to host memory
    std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>> depthPixSizeMapSgmUpscale_hmh =
      std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>();
    depthPixSizeMapSgmUpscale_hmh->associateWithMTLDevice(**this->_dev);
    depthPixSizeMapSgmUpscale_hmh->allocate2D(_sgmDepthPixSizeMap_dmp->getSize());
    depthPixSizeMapSgmUpscale_hmh->copyFromOtherBuffer(*_sgmDepthPixSizeMap_dmp);

    if (_refineParams.exportIntermediateCrossVolumes)
    {
        ALICEVISION_LOG_INFO(tile << "Export similarity volume cross (" << name << ").");

        const std::string volumeCrossPath = getFileNameFromIndex(_mp, tile.rc, mvsUtils::EFileType::volumeCross, "_" + name, tileBeginX, tileBeginY);

        exportSimilarityVolumeCross(volumeSim_hmh, depthPixSizeMapSgmUpscale_hmh, _mp, tile.rc, _refineParams, volumeCrossPath, tile.roi);

        ALICEVISION_LOG_INFO(tile << "Export similarity volume cross (" << name << ") done.");
    }

    if (_refineParams.exportIntermediateTopographicCutVolumes)
    {
        ALICEVISION_LOG_INFO(tile << "Export similarity volume topographic cut (" << name << ").");

        const std::string volumeCutPath =
          getFileNameFromIndex(_mp, tile.rc, mvsUtils::EFileType::volumeTopographicCut, "_" + name, tileBeginX, tileBeginY);

        exportSimilarityVolumeTopographicCut(volumeSim_hmh, depthPixSizeMapSgmUpscale_hmh, _mp, tile.rc, _refineParams, volumeCutPath, tile.roi);

        ALICEVISION_LOG_INFO(tile << "Export similarity volume topographic cut (" << name << ") done.");
    }

    if (_refineParams.exportIntermediateVolume9pCsv)
    {
        ALICEVISION_LOG_INFO(tile << "Export similarity volume 9 points CSV (" << name << ").");

        const std::string stats9Path = getFileNameFromIndex(_mp, tile.rc, mvsUtils::EFileType::stats9p, "_refine", tileBeginX, tileBeginY);

        exportSimilaritySamplesCSV(volumeSim_hmh, name, _refineParams, stats9Path, tile.roi);

        ALICEVISION_LOG_INFO(tile << "Export similarity volume 9 points CSV (" << name << ") done.");
    }
}

}  // namespace aliceVision::depthMap::mtl
