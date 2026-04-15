// This file is part of the AliceVision project.
// Copyright (c) 2017, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/Sgm.hpp>

#include <aliceVision/depthMap_mtl/DepthMapUtils.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>
#include <aliceVision/depthMap_mtl/VolumeIO.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceCache.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceDepthSimilarityMap.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceSimilarityVolume.hpp>

#include <aliceVision/mvsData/ROI.hpp>
#include <aliceVision/mvsUtils/fileIO.hpp>
#include <aliceVision/mvsUtils/MultiViewParams.hpp>
#include <aliceVision/mvsUtils/TileParams.hpp>
#include <aliceVision/numeric/numeric.hpp>
#include <aliceVision/system/Logger.hpp>

#include <memory>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceImpl.hpp>
#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

namespace aliceVision::depthMap::mtl {

Sgm::Sgm(const mvsUtils::MultiViewParams& mp,
         const mvsUtils::TileParams& tileParams,
         const SgmParams& sgmParams,
         bool computeDepthSimMap,
         bool computeNormalMap,
         const std::unique_ptr<MTLDeviceImpl>& dev)
  : _mp(mp),
    _tileParams(tileParams),
    _sgmParams(sgmParams),
    _computeDepthSimMap(computeDepthSimMap || sgmParams.exportIntermediateDepthSimMaps),
    _computeNormalMap(computeNormalMap || sgmParams.exportIntermediateNormalMaps),
    _dev(std::make_unique<MTLDeviceImpl>(*dev)) /* Explicit ARC copy */
{
    // Create memory instances
    this->_depths_hmh = std::make_unique<MTLDeviceMemory<float, 2, MemoryType::HostVisible>>();
    this->_depths_dmp = std::make_unique<MTLDeviceMemory<float, 2, MemoryType::DeviceOnly>>();
    this->_depthThicknessMap_dmp = std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>();
    this->_depthSimMap_dmp = std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>();
    this->_normalMap_dmp = std::make_unique<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>();
    this->_volumeBestSim_dmp = std::make_unique<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>();
    this->_volumeSecBestSim_dmp = std::make_unique<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>();
    this->_volumeSliceAccA_dmp = std::make_unique<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>();
    this->_volumeSliceAccB_dmp = std::make_unique<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>();
    this->_volumeAxisAcc_dmp = std::make_unique<MTLDeviceMemory<TSimAcc, 2, MemoryType::DeviceOnly>>();

    // Associate all MTLResources with the current device
    this->_depths_hmh->associateWithMTLDevice(**this->_dev);
    this->_depths_dmp->associateWithMTLDevice(**this->_dev);
    this->_depthThicknessMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_depthSimMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_normalMap_dmp->associateWithMTLDevice(**this->_dev);
    this->_volumeBestSim_dmp->associateWithMTLDevice(**this->_dev);
    this->_volumeSecBestSim_dmp->associateWithMTLDevice(**this->_dev);
    this->_volumeSliceAccA_dmp->associateWithMTLDevice(**this->_dev);
    this->_volumeSliceAccB_dmp->associateWithMTLDevice(**this->_dev);
    this->_volumeAxisAcc_dmp->associateWithMTLDevice(**this->_dev);

    // get tile maximum dimensions
    const int downscale = _sgmParams.scale * _sgmParams.stepXY;
    const int maxTileWidth = divideRoundUp(tileParams.bufferWidth, downscale);
    const int maxTileHeight = divideRoundUp(tileParams.bufferHeight, downscale);

    // compute map maximum dimensions
    const MTLResourceSize<2> mapDim(maxTileWidth, maxTileHeight);

    // allocate depth list in device memory
    {
        const MTLResourceSize<2> depthsDim(_sgmParams.maxDepths, 1);
        _depths_hmh->allocate2D(depthsDim);
        _depths_dmp->allocate2D(depthsDim);
    }

    // allocate depth thickness map in device memory
    _depthThicknessMap_dmp->allocate2D(mapDim);

    // allocate depth/sim map in device memory
    if (_computeDepthSimMap)
        _depthSimMap_dmp->allocate2D(mapDim);

    // allocate normal map in device memory
    if (_computeNormalMap)
        _normalMap_dmp->allocate2D(mapDim);

    // allocate similarity volumes in device memory
    {
        const MTLResourceSize<3> volDim(maxTileWidth, maxTileHeight, _sgmParams.maxDepths);

        _volumeBestSim_dmp->allocate3D(volDim);
        _volumeSecBestSim_dmp->allocate3D(volDim);
    }

    // allocate similarity volume optimization buffers
    if (sgmParams.doSgmOptimizeVolume)
    {
        const size_t maxTileSide = std::max(maxTileWidth, maxTileHeight);

        _volumeSliceAccA_dmp->allocate2D(MTLResourceSize<2>(maxTileSide, _sgmParams.maxDepths));
        _volumeSliceAccB_dmp->allocate2D(MTLResourceSize<2>(maxTileSide, _sgmParams.maxDepths));
        _volumeAxisAcc_dmp->allocate2D(MTLResourceSize<2>(maxTileSide, 1));
    }
}

double Sgm::getDeviceMemoryConsumption() const
{
    size_t bytes = 0;

    bytes += _depths_dmp->getAllocationSize();
    bytes += _depthThicknessMap_dmp->getAllocationSize();
    bytes += _depthSimMap_dmp->getAllocationSize();
    bytes += _normalMap_dmp->getAllocationSize();
    bytes += _volumeBestSim_dmp->getAllocationSize();
    bytes += _volumeSecBestSim_dmp->getAllocationSize();
    bytes += _volumeSliceAccA_dmp->getAllocationSize();
    bytes += _volumeSliceAccB_dmp->getAllocationSize();
    bytes += _volumeAxisAcc_dmp->getAllocationSize();

    return (double(bytes) / (1024.0 * 1024.0));
}

double Sgm::getDeviceMemoryConsumptionUnpadded() const
{
    // Metal does not pad MTLBuffers
    return this->getDeviceMemoryConsumption();
}

void Sgm::sgmRc(const Tile& tile, const SgmDepthList& tileDepthList)
{
    const IndexT viewId = _mp.getViewId(tile.rc);

    ALICEVISION_LOG_INFO(tile << "SGM depth/thickness map of view ID: " << viewId << ", RC: " << tile.rc << " (" << (tile.rc + 1) << " / "
                              << _mp.ncams << ").");

    // check SGM depth list and T cameras
    if (tile.sgmTCams.empty() || tileDepthList.getDepths().empty())
        ALICEVISION_THROW_ERROR(tile << "Cannot compute Semi-Global Matching, no depths or no T cameras (viewID: " << viewId << ").");

    // copy rc depth data in page-locked host memory
    _depths_hmh->writeFromHost([&](std::mdspan<float, std::dextents<size_t, 2>> contents) {
        for (size_t i = 0; i < tileDepthList.getDepths().size(); ++i)
            contents[0, i] = tileDepthList.getDepths()[i];
    });

    // copy rc depth data in device memory
    _depths_dmp->copyFromOtherBuffer(*_depths_hmh);

    // compute best sim and second best sim volumes
    computeSimilarityVolumes(tile, tileDepthList);

    // export intermediate volume information (if requested by user)
    exportVolumeInformation(tile, tileDepthList, _volumeSecBestSim_dmp, "beforeFiltering");

    // this is here for experimental purposes
    // to show how SGGC work on non optimized depthmaps
    // it must equals to true in normal case
    if (_sgmParams.doSgmOptimizeVolume)
    {
        optimizeSimilarityVolume(tile, tileDepthList);
    }
    else
    {
        // best sim volume is normally reuse to put optimized similarity
        _volumeBestSim_dmp->copyFromOtherBuffer(*_volumeSecBestSim_dmp);
    }

    // export intermediate volume information (if requested by user)
    exportVolumeInformation(tile, tileDepthList, _volumeBestSim_dmp, "afterFiltering");

    // retrieve best depth
    retrieveBestDepth(tile, tileDepthList);

    // export intermediate depth/sim map (if requested by user)
    if (_sgmParams.exportIntermediateDepthSimMaps)
    {
        writeDepthSimMap(tile.rc, _mp, _tileParams, tile.roi, _depthSimMap_dmp, _sgmParams.scale, _sgmParams.stepXY, "sgm");
    }

    // compute normal map from depth/sim map if needed
    if (_computeNormalMap)
    {
        // downscale the region of interest
        const ROI downscaledRoi = downscaleROI(tile.roi, _sgmParams.scale * _sgmParams.stepXY);

        // get R device camera parameters id from cache
        DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);
        const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tile.rc, _sgmParams.scale, _mp);

        ALICEVISION_LOG_INFO(tile << "SGM compute normal map of view ID: " << viewId << ", RC: " << tile.rc << " (" << (tile.rc + 1) << " / "
                                  << _mp.ncams << ").");

        MTL_depthSimMapComputeNormal(_normalMap_dmp, _depthSimMap_dmp, rcDeviceCameraParamsId, _sgmParams.stepXY, downscaledRoi, **this->_dev);

        // export intermediate normal map (if requested by user)
        if (_sgmParams.exportIntermediateNormalMaps)
        {
            writeNormalMap(tile.rc, _mp, _tileParams, tile.roi, _normalMap_dmp, _sgmParams.scale, _sgmParams.stepXY, "sgm");
        }
    }

    ALICEVISION_LOG_INFO(tile << "SGM depth/thickness map done.");
}

void Sgm::smoothThicknessMap(const Tile& tile, const RefineParams& refineParams)
{
    ALICEVISION_LOG_INFO(tile << "SGM Smooth thickness map.");

    // downscale the region of interest
    const ROI downscaledRoi = downscaleROI(tile.roi, _sgmParams.scale * _sgmParams.stepXY);

    // in-place result thickness map smoothing with adjacent pixels
    MTL_depthThicknessSmoothThickness(this->_depthThicknessMap_dmp, this->_sgmParams, refineParams, downscaledRoi, **this->_dev);

    ALICEVISION_LOG_INFO(tile << "SGM Smooth thickness map done.");
}

void Sgm::computeSimilarityVolumes(const Tile& tile, const SgmDepthList& tileDepthList)
{
    ALICEVISION_LOG_INFO(tile << "SGM Compute similarity volume.");

    // downscale the region of interest
    const ROI downscaledRoi = downscaleROI(tile.roi, _sgmParams.scale * _sgmParams.stepXY);

    // initialize the two similarity volumes at 255
    MTL_volumeInitTSim(this->_volumeBestSim_dmp, 255.f, **this->_dev);
    MTL_volumeInitTSim(this->_volumeSecBestSim_dmp, 255.f, **this->_dev);

    // get device cache instance
    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);

    // get R device camera parameters id from cache
    const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tile.rc, _sgmParams.scale, _mp);

    // get R device mipmap image from cache
    const DeviceMipmapImage& rcDeviceMipmapImage = deviceCache.requestMipmapImage(tile.rc, _mp);

    // compute similarity volume per Rc Tc
    for (std::size_t tci = 0; tci < tile.sgmTCams.size(); ++tci)
    {
        const int tc = tile.sgmTCams.at(tci);

        const int firstDepth = tileDepthList.getDepthsTcLimits()[tci].x;
        const int lastDepth = firstDepth + tileDepthList.getDepthsTcLimits()[tci].y;

        const Range tcDepthRange(firstDepth, lastDepth);

        // get T device camera parameters id from cache
        const int tcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tc, _sgmParams.scale, _mp);

        // get T device mipmap image from cache
        const DeviceMipmapImage& tcDeviceMipmapImage = deviceCache.requestMipmapImage(tc, _mp);

        ALICEVISION_LOG_DEBUG(tile << "Compute similarity volume:" << std::endl
                                   << "\t- RC: " << tile.rc << std::endl
                                   << "\t- TC: " << tc << " (" << (tci + 1) << "/" << tile.sgmTCams.size() << ")" << std::endl
                                   << "\t- RC camera parameters ID: " << rcDeviceCameraParamsId << std::endl
                                   << "\t- TC camera parameters ID: " << tcDeviceCameraParamsId << std::endl
                                   << "\t- TC first depth: " << firstDepth << std::endl
                                   << "\t- TC last depth: " << lastDepth << std::endl
                                   << "\t- Tile range x: [" << downscaledRoi.x.begin << " - " << downscaledRoi.x.end << "]" << std::endl
                                   << "\t- Tile range y: [" << downscaledRoi.y.begin << " - " << downscaledRoi.y.end << "]" << std::endl);

        MTL_volumeComputeSimilarity(this->_volumeBestSim_dmp,
                                    this->_volumeSecBestSim_dmp,
                                    this->_depths_dmp,
                                    rcDeviceCameraParamsId,
                                    tcDeviceCameraParamsId,
                                    rcDeviceMipmapImage,
                                    tcDeviceMipmapImage,
                                    this->_sgmParams,
                                    tcDepthRange,
                                    downscaledRoi,
                                    **this->_dev);
    }

    // update second best uninitialized similarity volume values with first best similarity volume values
    // - allows to avoid the particular case with a single tc (second best volume has no valid similarity values)
    // - useful if a tc alone contributes to the calculation of a subpart of the similarity volume
    if (_sgmParams.updateUninitializedSim)  // should always be true, false for debug purposes
    {
        ALICEVISION_LOG_DEBUG(tile << "SGM Update uninitialized similarity volume values from best similarity volume.");

        MTL_volumeUpdateUninitializedSimilarity(this->_volumeBestSim_dmp, this->_volumeSecBestSim_dmp, **this->_dev);
    }

    ALICEVISION_LOG_INFO(tile << "SGM Compute similarity volume done.");
}

void Sgm::optimizeSimilarityVolume(const Tile& tile, const SgmDepthList& tileDepthList)
{
    ALICEVISION_LOG_INFO(tile << "SGM Optimizing volume.");

    // downscale the region of interest
    const ROI downscaledRoi = downscaleROI(tile.roi, _sgmParams.scale * _sgmParams.stepXY);

    // get R device mipmap image from cache
    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);
    const DeviceMipmapImage& rcDeviceMipmapImage = deviceCache.requestMipmapImage(tile.rc, _mp);

    MTL_volumeOptimize(this->_volumeBestSim_dmp,     // output volume (reuse best sim to put optimized similarity)
                       this->_volumeSliceAccA_dmp,   // slice A accumulation buffer pre-allocate
                       this->_volumeSliceAccB_dmp,   // slice B accumulation buffer pre-allocate
                       this->_volumeAxisAcc_dmp,     // axis accumulation buffer pre-allocate
                       this->_volumeSecBestSim_dmp,  // input volume
                       rcDeviceMipmapImage,
                       this->_sgmParams,
                       tileDepthList.getDepths().size(),
                       downscaledRoi,
                       **this->_dev);

    ALICEVISION_LOG_INFO(tile << "SGM Optimizing volume done.");
}

void Sgm::retrieveBestDepth(const Tile& tile, const SgmDepthList& tileDepthList)
{
    ALICEVISION_LOG_INFO(tile << "SGM Retrieve best depth in volume.");

    // downscale the region of interest
    const ROI downscaledRoi = downscaleROI(tile.roi, _sgmParams.scale * _sgmParams.stepXY);

    // get depth range
    const Range depthRange(0, tileDepthList.getDepths().size());

    // get R device camera parameters id from cache
    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**this->_dev);
    const int rcDeviceCameraParamsId = deviceCache.requestCameraParamsId(tile.rc, 1, _mp);

    MTL_volumeRetrieveBestDepth(this->_depthThicknessMap_dmp,  // output depth thickness map
                                this->_depthSimMap_dmp,        // output depth/sim map (or empty)
                                this->_computeDepthSimMap,     // Whether to compute the depth sim map
                                this->_depths_dmp,             // rc depth
                                this->_volumeBestSim_dmp,      // second best sim volume optimized in best sim volume
                                rcDeviceCameraParamsId,
                                this->_sgmParams,
                                depthRange,
                                downscaledRoi,
                                **this->_dev);

    ALICEVISION_LOG_INFO(tile << "SGM Retrieve best depth in volume done.");
}

void Sgm::exportVolumeInformation(const Tile& tile,
                                  const SgmDepthList& tileDepthList,
                                  const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::DeviceOnly>>& in_volume_dmp,
                                  const std::string& name) const
{
    if (!_sgmParams.exportIntermediateVolumes && !_sgmParams.exportIntermediateCrossVolumes && !_sgmParams.exportIntermediateVolume9pCsv)
    {
        // nothing to do
        return;
    }

    // get file tile begin indexes (default is single tile)
    int tileBeginX = -1;
    int tileBeginY = -1;

    if (tile.nbTiles > 1)
    {
        tileBeginX = tile.roi.x.begin;
        tileBeginY = tile.roi.y.begin;
    }

    // copy device similarity volume to host memory
    std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>> volumeSim_hmh =
      std::make_unique<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>();
    volumeSim_hmh->associateWithMTLDevice(**this->_dev);
    volumeSim_hmh->allocate3D(in_volume_dmp->getSize());
    volumeSim_hmh->copyFromOtherBuffer(*in_volume_dmp);

    if (_sgmParams.exportIntermediateVolumes)
    {
        ALICEVISION_LOG_INFO(tile << "Export similarity volume (" << name << ").");

        const std::string volumePath = getFileNameFromIndex(_mp, tile.rc, mvsUtils::EFileType::volume, "_" + name, tileBeginX, tileBeginY);

        exportSimilarityVolume(volumeSim_hmh, tileDepthList.getDepths(), _mp, tile.rc, _sgmParams, volumePath, tile.roi);

        ALICEVISION_LOG_INFO(tile << "Export similarity volume (" << name << ") done.");
    }

    if (_sgmParams.exportIntermediateCrossVolumes)
    {
        ALICEVISION_LOG_INFO(tile << "Export similarity volume cross (" << name << ").");

        const std::string volumeCrossPath = getFileNameFromIndex(_mp, tile.rc, mvsUtils::EFileType::volumeCross, "_" + name, tileBeginX, tileBeginY);

        exportSimilarityVolumeCross(volumeSim_hmh, tileDepthList.getDepths(), _mp, tile.rc, _sgmParams, volumeCrossPath, tile.roi);

        ALICEVISION_LOG_INFO(tile << "Export similarity volume cross (" << name << ") done.");
    }

    if (_sgmParams.exportIntermediateTopographicCutVolumes)
    {
        ALICEVISION_LOG_INFO(tile << "Export similarity volume topographic cut (" << name << ").");

        const std::string volumeCutPath =
          getFileNameFromIndex(_mp, tile.rc, mvsUtils::EFileType::volumeTopographicCut, "_" + name, tileBeginX, tileBeginY);

        exportSimilarityVolumeTopographicCut(volumeSim_hmh, tileDepthList.getDepths(), _mp, tile.rc, _sgmParams, volumeCutPath, tile.roi);

        ALICEVISION_LOG_INFO(tile << "Export similarity volume topographic cut (" << name << ") done.");
    }

    if (_sgmParams.exportIntermediateVolume9pCsv)
    {
        ALICEVISION_LOG_INFO(tile << "Export similarity volume 9 points CSV (" << name << ").");

        const std::string stats9Path = getFileNameFromIndex(_mp, tile.rc, mvsUtils::EFileType::stats9p, "_sgm", tileBeginX, tileBeginY);

        exportSimilaritySamplesCSV(volumeSim_hmh, tileDepthList.getDepths(), name, _sgmParams, stats9Path, tile.roi);

        ALICEVISION_LOG_INFO(tile << "Export similarity volume 9 points CSV (" << name << ") done.");
    }
}

const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& Sgm::getDeviceDepthThicknessMap() const
{ return this->_depthThicknessMap_dmp; }

const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::DeviceOnly>>& Sgm::getDeviceDepthSimMap() const { return this->_depthSimMap_dmp; }

const std::unique_ptr<MTLDeviceMemory<float3, 2, MemoryType::DeviceOnly>>& Sgm::getDeviceNormalMap() const { return this->_normalMap_dmp; }

}  // namespace aliceVision::depthMap::mtl
