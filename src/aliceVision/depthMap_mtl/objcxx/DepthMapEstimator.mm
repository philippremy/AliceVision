// This file is part of the AliceVision project.
// Copyright (c) 2023, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/DepthMapEstimator.hpp>

#include <aliceVision/depthMap_mtl/Config.h>
#include <aliceVision/depthMap_mtl/DepthMapUtils.hpp>
#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/PatchPattern.hpp>
#include <aliceVision/depthMap_mtl/Refine.hpp>
#include <aliceVision/depthMap_mtl/Sgm.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>
#include <aliceVision/depthMap_mtl/private/DeviceCache.hpp>
#include <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#include <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#include <aliceVision/depthMap_mtl/private/DeviceUtils.hpp>
#include <aliceVision/depthMap_mtl/private/MemoryUtils.hpp>

#include <aliceVision/mvsUtils/ImagesCache.hpp>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceImpl.hpp>
#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

namespace aliceVision::depthMap::mtl {

DepthMapEstimator::DepthMapEstimator(const mvsUtils::MultiViewParams& mp,
                                     const mvsUtils::TileParams& tileParams,
                                     const DepthMapParams& depthMapParams,
                                     const SgmParams& sgmParams,
                                     const RefineParams& refineParams)
  : _mp(mp),
    _tileParams(tileParams),
    _depthMapParams(depthMapParams),
    _sgmParams(sgmParams),
    _refineParams(refineParams)
{
    // Compute maximum downscale (scaleStep)
    const int maxDownscale = std::max(_sgmParams.scale * _sgmParams.stepXY, _refineParams.scale * _refineParams.stepXY);

    // Compute tile ROI list
    getTileRoiList(_tileParams, _mp.getMaxImageWidth(), _mp.getMaxImageHeight(), maxDownscale, _tileRoiList);

    // Log tiling information and ROI list
    logTileRoiList(_tileParams, _mp.getMaxImageWidth(), _mp.getMaxImageHeight(), maxDownscale, _tileRoiList);

    // Log SGM downscale & stepXY
    ALICEVISION_LOG_INFO("SGM parameters:" << std::endl << "\t- scale: " << _sgmParams.scale << std::endl << "\t- stepXY: " << _sgmParams.stepXY);

    // Log Refine downscale & stepXY
    ALICEVISION_LOG_INFO("Refine parameters:" << std::endl
                                              << "\t- scale: " << _refineParams.scale << std::endl
                                              << "\t- stepXY: " << _refineParams.stepXY);
}

int DepthMapEstimator::getNbSimultaneousTiles(const std::unique_ptr<MTLDeviceImpl>& dev) const
{
    const int nbTilesPerCamera = _tileRoiList.size();

    // mipmap image cost
    const double mipmapCostMB = (_mp.getMaxImageWidth() * _mp.getMaxImageHeight() * sizeof(MTLRGBA)) / (1024.0 * 1024.0);  // process downscale apply

    // cameras cost per R camera computation
    // Rc mipmap + Tcs mipmaps
    const double rcCamsCostMB = mipmapCostMB + _depthMapParams.maxTCams * mipmapCostMB;

    // number of camera parameters in device constant memory
    // (Rc + Tcs) * 2 (SGM + Refine downscale) + 1 (SGM needs downscale 1)
    // note: special case SGM downsccale = Refine downscale not handle
    const int rcNbCameraParams = (_depthMapParams.useRefine) ? 2 : 1;
    const int rcCamParams = (1 /* rc */ + _depthMapParams.maxTCams) * rcNbCameraParams + ((_refineParams.scale > 1) ? 1 : 0);

    // single tile SGM cost
    double sgmTileCostMB = 0.0;
    double sgmTileCostUnpaddedMB = 0.0;

    {
        const bool sgmComputeDepthSimMap = !_depthMapParams.useRefine;
        const bool sgmComputeNormalMap = _refineParams.useSgmNormalMap;

        Sgm sgm(_mp, _tileParams, _sgmParams, sgmComputeDepthSimMap, sgmComputeNormalMap, dev);
        sgmTileCostMB = sgm.getDeviceMemoryConsumption();
        sgmTileCostUnpaddedMB = sgm.getDeviceMemoryConsumptionUnpadded();
    }

    // single tile Refine cost
    double refineTileCostMB = 0.0;
    double refineTileCostUnpaddedMB = 0.0;

    if (_depthMapParams.useRefine)
    {
        Refine refine(_mp, _tileParams, _refineParams, dev);
        refineTileCostMB = refine.getDeviceMemoryConsumption();
        refineTileCostUnpaddedMB = refine.getDeviceMemoryConsumptionUnpadded();
    }

    // tile computation cost
    // SGM tile cost + Refine tile cost
    const double tileCostMB = sgmTileCostMB + refineTileCostMB;
    const double tileCostUnpaddedMB = sgmTileCostUnpaddedMB + refineTileCostUnpaddedMB;

    // min/max cost of an R camera computation
    // min cost for a single tile computation
    // max cost for all tiles computation
    const double rcMinCostMB = rcCamsCostMB + tileCostMB;
    const double rcMaxCostMB = rcCamsCostMB + nbTilesPerCamera * tileCostMB;

    // available device memory
    double deviceMemoryMB;
    {
        double availableMB, usedMB, totalMB;
        getDeviceMemoryInfo(**dev, availableMB, usedMB, totalMB);
        deviceMemoryMB = availableMB;  // Do not apply 80% margin, this is too much because Apple might cache heavily
    }

    // number of full R camera computation that can be done simultaneously
    int nbSimultaneousFullRc = static_cast<int>(deviceMemoryMB / rcMaxCostMB);

    // try to add a part of an R camera computation
    int nbRemainingTiles = 0;
    {
        const double remainingMemoryMB = deviceMemoryMB - (nbSimultaneousFullRc * rcMaxCostMB);
        nbRemainingTiles = static_cast<int>(std::max(0.0, remainingMemoryMB - rcCamsCostMB) / tileCostMB);
    }

    // check that we do not need more constant camera parameters than the ones in device constant memory
    if (ALICEVISION_DEVICE_MAX_CONSTANT_CAMERA_PARAM_SETS < ((nbSimultaneousFullRc + ((nbRemainingTiles > 0) ? 1 : 0)) * rcCamParams))
    {
        const int previousNbSimultaneousFullRc = nbSimultaneousFullRc;
        nbSimultaneousFullRc = static_cast<int>(ALICEVISION_DEVICE_MAX_CONSTANT_CAMERA_PARAM_SETS / rcCamParams);

        ALICEVISION_LOG_INFO("DepthMapEstimator::getNbSimultaneousTiles(): limit the number of simultaneous RC due to "
                             << "the max constant memory for camera params from " << previousNbSimultaneousFullRc << " to " << nbSimultaneousFullRc);
        nbRemainingTiles = 0;
    }

    // compute number of simultaneous tiles
    const int outNbSimultaneousTiles = nbSimultaneousFullRc * nbTilesPerCamera + nbRemainingTiles;

    // log memory information
    ALICEVISION_LOG_INFO("Device memory:" << std::endl
                                          << "\t- available: " << deviceMemoryMB << " MB" << std::endl
                                          << "\t- requirement for the first tile: " << rcMinCostMB << " MB" << std::endl
                                          << "\t- # computation buffers per tile: " << tileCostMB << " MB"
                                          << " (Sgm: " << sgmTileCostMB << " MB"
                                          << ", Refine: " << refineTileCostMB << " MB)" << std::endl
                                          << "\t- # input images (R + " << _depthMapParams.maxTCams << " Ts): " << rcCamsCostMB
                                          << " MB (single mipmap image size: " << mipmapCostMB << " MB)");

    ALICEVISION_LOG_DEBUG("Theoretical device memory cost for a tile without padding: " << tileCostUnpaddedMB << " MB"
                                                                                        << " (Sgm: " << sgmTileCostUnpaddedMB << " MB"
                                                                                        << ", Refine: " << refineTileCostUnpaddedMB << " MB)");

    ALICEVISION_LOG_INFO("Parallelization:" << std::endl
                                            << "\t- # tiles per image: " << nbTilesPerCamera << std::endl
                                            << "\t- # simultaneous depth maps computation: "
                                            << ((nbRemainingTiles < 1) ? nbSimultaneousFullRc : (nbSimultaneousFullRc + 1)) << std::endl
                                            << "\t- # simultaneous tiles computation: " << outNbSimultaneousTiles);

    // check at least one single tile computation
    if (rcCamParams > ALICEVISION_DEVICE_MAX_CONSTANT_CAMERA_PARAM_SETS || outNbSimultaneousTiles < 1)
    {
        ALICEVISION_THROW_ERROR("Not enough GPU memory to compute a single tile.");
    }

    return outNbSimultaneousTiles;
}

void DepthMapEstimator::getTilesList(const std::vector<int>& cams, std::vector<Tile>& tiles) const
{
    const size_t nbTilesPerCamera = _tileRoiList.size();

    // tiles list should be empty
    assert(tiles.empty());

    // reserve memory
    tiles.reserve(cams.size() * nbTilesPerCamera);

    for (int rc : cams)
    {
        // get R camera Tcs list
        const std::vector<int> tCams = _mp.findNearestCamsFromLandmarks(rc, _depthMapParams.maxTCams).getDataWritable();

        // get R camera ROI
        const ROI rcImageRoi(Range(0, _mp.getWidth(rc)), Range(0, _mp.getHeight(rc)));

        for (std::size_t i = 0; i < nbTilesPerCamera; ++i)
        {
            Tile t;

            t.id = i;
            t.nbTiles = nbTilesPerCamera;
            t.rc = rc;
            t.roi = intersect(_tileRoiList.at(i), rcImageRoi);

            if (t.roi.isEmpty())
            {
                // do nothing, this ROI cannot intersect the R camera ROI.
            }
            else if (_depthMapParams.chooseTCamsPerTile)
            {
                // find nearest T cameras per tile
                t.sgmTCams = _mp.findTileNearestCams(rc, _sgmParams.maxTCamsPerTile, tCams, t.roi);

                if (_depthMapParams.useRefine)
                    t.refineTCams = _mp.findTileNearestCams(rc, _refineParams.maxTCamsPerTile, tCams, t.roi);
            }
            else
            {
                // use previously selected T cameras from the entire image
                t.sgmTCams = tCams;
                t.refineTCams = tCams;
            }

            tiles.push_back(t);
        }
    }
}

void DepthMapEstimator::compute(std::unique_ptr<MTLDeviceImpl> dev, const std::vector<int>& cams)
{
    ALICEVISION_LOG_INFO("Preloading MTLPipelineStates. This can take a while...");
    // We want to initialize all device pipelines early
    /* clang-format off */
    DeviceManager::instance().getCMDManager(**dev).preloadPipelineStates(
        {
            "aliceVision::depthMap::mtl::kernel_downscaleWithGaussianBlur",
            "aliceVision::depthMap::mtl::kernel_rgb2lab",
            "aliceVision::depthMap::mtl::kernel_createMipmappedArrayLevel",
            "aliceVision::depthMap::mtl::kernel_depthSimMapComputeNormal",
            "aliceVision::depthMap::mtl::kernel_depthThicknessSmoothThickness",
            "aliceVision::depthMap::mtl::kernel_volumeInit_TSim",
            "aliceVision::depthMap::mtl::kernel_volumeComputeSimilarity",
            "aliceVision::depthMap::mtl::kernel_volumeUpdateUninitialized",
            "aliceVision::depthMap::mtl::kernel_volumeGetVolumeXZSlice_TSimTSimAcc",
            "aliceVision::depthMap::mtl::kernel_volumeInitVolumeYSlice_TSim",
            "aliceVision::depthMap::mtl::kernel_volumeComputeBestZInSlice",
            "aliceVision::depthMap::mtl::kernel_volumeGetVolumeXZSlice_TSimAccTSim",
            "aliceVision::depthMap::mtl::kernel_volumeAggregateCostVolumeAtXInSlices",
            "aliceVision::depthMap::mtl::kernel_volumeRetrieveBestDepth_DepthSimMap",
            "aliceVision::depthMap::mtl::kernel_volumeRetrieveBestDepth_NoDepthSimMap",
            "aliceVision::depthMap::mtl::kernel_computeSgmUpscaledDepthPixSizeMap_Bilinear",
            "aliceVision::depthMap::mtl::kernel_computeSgmUpscaledDepthPixSizeMap_NearestNeighbor",
            "aliceVision::depthMap::mtl::kernel_mapUpscale_float3",
            "aliceVision::depthMap::mtl::kernel_depthSimMapCopyDepthOnly",
            "aliceVision::depthMap::mtl::kernel_volumeInit_TSimRefine",
            "aliceVision::depthMap::mtl::kernel_volumeRefineSimilarity_SgmNormalMap",
            "aliceVision::depthMap::mtl::kernel_volumeRefineSimilarity_NoSgmNormalMap",
            "aliceVision::depthMap::mtl::kernel_volumeRefineBestDepth",
            "aliceVision::depthMap::mtl::kernel_optimizeVarLofLABtoW",
            "aliceVision::depthMap::mtl::kernel_optimizeGetOptDeptMapFromOptDepthSimMap",
            "aliceVision::depthMap::mtl::kernel_optimizeDepthSimMap",
        },
        "aliceVision_depthMap_mtl_kernels"
    );
    /* clang-format on */
    ALICEVISION_LOG_INFO("Loaded MTLPipelineStates.");

    // initialize RAM image cache
    // note: maybe move it as class member in order to share it across multiple GPUs
    mvsUtils::ImagesCache<image::Image<image::RGBAfColor>> ic(_mp, image::EImageColorSpace::LINEAR);

    // build tile list order by R camera
    std::vector<Tile> tiles;
    getTilesList(cams, tiles);

    // get maximum number of simultaneous tiles
    // for now, we use one CUDA stream per tile (SGM + Refine)
    const int nbStreams = std::min(getNbSimultaneousTiles(dev), static_cast<int>(tiles.size()));

    // constants
    const bool hasRcSameDownscale = (_sgmParams.scale == _refineParams.scale);  // we only need one camera params per image
    const bool hasRcWithoutDownscale =
      _sgmParams.scale == 1 || (_depthMapParams.useRefine && _refineParams.scale == 1);  // we need R camera params SGM (downscale = 1)
    const int nbCameraParamsPerSgm =
      (1 + _depthMapParams.maxTCams) + (hasRcWithoutDownscale ? 0 : 1);  // number of Sgm camera parameters per R camera
    const int nbCameraParamsPerRefine =
      (_depthMapParams.useRefine && !hasRcSameDownscale) ? (1 + _depthMapParams.maxTCams) : 0;  // number of Refine camera parameters per R camera

    // build device cache
    const int nbTilesPerCamera = static_cast<int>(_tileRoiList.size());

    int nbRcPerBatch = divideRoundUp(nbStreams, nbTilesPerCamera);  // number of R cameras in the same batch
    if (nbRcPerBatch * (nbCameraParamsPerSgm + nbCameraParamsPerRefine) > ALICEVISION_DEVICE_MAX_CONSTANT_CAMERA_PARAM_SETS)
    {
        int previousNbRcPerBatch = nbRcPerBatch;
        nbRcPerBatch = ALICEVISION_DEVICE_MAX_CONSTANT_CAMERA_PARAM_SETS / (nbCameraParamsPerSgm + nbCameraParamsPerRefine);
        ALICEVISION_LOG_INFO("DepthMapEstimator::compute(): limit the number of simultaneous RC due to the max constant"
                             << " memory for camera params from " << previousNbRcPerBatch << " to " << nbRcPerBatch);
    }

    const int nbCamerasParamsPerBatch =
      nbRcPerBatch * (nbCameraParamsPerSgm + nbCameraParamsPerRefine);                 // number of camera parameters in the same batch
    const int nbTilesPerBatch = nbRcPerBatch * nbTilesPerCamera;                       // number of tiles in the same batch
    const int nbMipmapImagesPerBatch = nbRcPerBatch * (1 + _depthMapParams.maxTCams);  // number of camera mipmap image in the same batch

    DeviceCache& deviceCache = DeviceManager::instance().getDeviceCache(**dev);
    deviceCache.buildCache(nbMipmapImagesPerBatch, nbCamerasParamsPerBatch);

    // build custom patch pattern in CUDA constant memory
    if (_sgmParams.useCustomPatchPattern || _refineParams.useCustomPatchPattern)
        buildCustomPatchPattern(_depthMapParams.customPatchPattern, dev);

    // allocate Sgm and Refine per stream in device memory
    std::vector<std::unique_ptr<Sgm>> sgmPerStream;
    std::vector<std::unique_ptr<Refine>> refinePerStream;

    sgmPerStream.reserve(tiles.size());
    refinePerStream.reserve(_depthMapParams.useRefine ? tiles.size() : 0);

    // initialize Sgm and Refine objects
    {
        const bool sgmComputeDepthSimMap = !_depthMapParams.useRefine;
        const bool sgmComputeNormalMap = _refineParams.useSgmNormalMap;

        // initialize Sgm objects
        for (int i = 0; i < tiles.size(); ++i)
            sgmPerStream.emplace_back(std::make_unique<Sgm>(_mp, _tileParams, _sgmParams, sgmComputeDepthSimMap, sgmComputeNormalMap, dev));

        // initialize Refine objects
        if (_depthMapParams.useRefine)
            for (int i = 0; i < tiles.size(); ++i)
                refinePerStream.emplace_back(std::make_unique<Refine>(_mp, _tileParams, _refineParams, dev));
    }

    // allocate final deth/similarity map tile list in host memory
    std::vector<std::vector<std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>>> depthSimMapTilePerCam(nbRcPerBatch);
    std::vector<std::vector<std::pair<float, float>>> depthMinMaxTilePerCam(nbRcPerBatch);

    for (int i = 0; i < nbRcPerBatch; ++i)
    {
        auto& depthSimMapTiles = depthSimMapTilePerCam.at(i);
        auto& depthMinMaxTiles = depthMinMaxTilePerCam.at(i);

        depthSimMapTiles.resize(nbTilesPerCamera);
        depthMinMaxTiles.resize(nbTilesPerCamera);

        for (int j = 0; j < nbTilesPerCamera; ++j)
        {
            if (_depthMapParams.useRefine)
            {
                depthSimMapTiles.at(j) = std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>();
                depthSimMapTiles.at(j)->associateWithMTLDevice(**dev);
                depthSimMapTiles.at(j)->allocate2D(refinePerStream.front()->getDeviceDepthSimMap()->getSize());
            }
            else  // final depth/similarity map is SGM only
            {
                depthSimMapTiles.at(j) = std::make_unique<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>();
                depthSimMapTiles.at(j)->associateWithMTLDevice(**dev);
                depthSimMapTiles.at(j)->allocate2D(sgmPerStream.front()->getDeviceDepthSimMap()->getSize());
            }
        }
    }

    // log device memory information
    logDeviceMemoryInfo(**dev);

    // compute number of batches
    const int nbBatches = divideRoundUp(static_cast<int>(tiles.size()), nbTilesPerBatch);
    const int minMipmapDownscale = std::min(_refineParams.scale, _sgmParams.scale);
    const int maxMipmapDownscale = std::max(_refineParams.scale, _sgmParams.scale) * std::pow(2, 6);  // we add 6 downscale levels

    // compute each batch of R cameras
    for (int b = 0; b < nbBatches; ++b)
    {
        // find first/last tile to compute
        const int firstTileIndex = b * nbTilesPerBatch;
        const int lastTileIndex = std::min((b + 1) * nbTilesPerBatch, static_cast<int>(tiles.size()));

        // load tile R and corresponding T cameras in device cache
        for (int i = firstTileIndex; i < lastTileIndex; ++i)
        {
            const Tile& tile = tiles.at(i);

            // add Sgm R camera to Device cache
            deviceCache.addMipmapImage(tile.rc, minMipmapDownscale, maxMipmapDownscale, ic, _mp);
            deviceCache.addCameraParams(tile.rc, _sgmParams.scale, _mp);

            // add Sgm T cameras to Device cache
            for (const int tc : tile.sgmTCams)
            {
                deviceCache.addMipmapImage(tc, minMipmapDownscale, maxMipmapDownscale, ic, _mp);
                deviceCache.addCameraParams(tc, _sgmParams.scale, _mp);
            }

            if (_depthMapParams.useRefine)
            {
                // add Refine R camera to Device cache
                deviceCache.addCameraParams(tile.rc, _refineParams.scale, _mp);

                // add Refine T cameras to Device cache
                for (const int tc : tile.refineTCams)
                {
                    deviceCache.addMipmapImage(tc, minMipmapDownscale, maxMipmapDownscale, ic, _mp);
                    deviceCache.addCameraParams(tc, _refineParams.scale, _mp);
                }
            }

            if (!hasRcWithoutDownscale)
            {
                // add SGM R camera at scale 1 to Device cache.
                // R camera parameters at scale 1 are required for SGM retrieve best depth
                deviceCache.addCameraParams(tile.rc, 1, _mp);
            }
        }

        // compute each batch tile
        for (int i = firstTileIndex; i < lastTileIndex; ++i)
        {
            Tile& tile = tiles.at(i);
            const int batchCamIndex = tile.rc % nbRcPerBatch;

            // do not compute empty ROI
            // some images in the dataset may be smaller than others
            if (tile.roi.isEmpty())
            {
                ALICEVISION_LOG_INFO(tile << "Skipping tile (ROI is empty).");
                sgmPerStream.at(i).reset(nullptr);
                if (_depthMapParams.useRefine)
                    refinePerStream.at(i).reset(nullptr);
                continue;
            }

            // get tile result depth/similarity map in host memory
            std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>& tileDepthSimMap_hmh =
              depthSimMapTilePerCam.at(batchCamIndex).at(tile.id);

            // check T cameras
            if (tile.sgmTCams.empty() || (_depthMapParams.useRefine && tile.refineTCams.empty()))  // no T camera found
            {
                resetDepthSimMap(tileDepthSimMap_hmh);
                ALICEVISION_LOG_INFO(tile << "Skipping tile (no T camera found).");
                sgmPerStream.at(i).reset(nullptr);
                if (_depthMapParams.useRefine)
                    refinePerStream.at(i).reset(nullptr);
                continue;
            }

            // build tile SGM depth list
            SgmDepthList sgmDepthList(_mp, _sgmParams, tile);

            // compute the R camera depth list
            sgmDepthList.computeListRc();

            // check number of depths
            if (sgmDepthList.getDepths().empty())  // no depth found
            {
                resetDepthSimMap(tileDepthSimMap_hmh);
                depthMinMaxTilePerCam.at(batchCamIndex).at(tile.id) = {0.f, 0.f};
                ALICEVISION_LOG_INFO(tile << "Skipping tile (no depths found).");
                sgmPerStream.at(i).reset(nullptr);
                if (_depthMapParams.useRefine)
                    refinePerStream.at(i).reset(nullptr);
                continue;
            }

            // remove T cameras with no depth found.
            sgmDepthList.removeTcWithNoDepth(tile);

            // store min/max depth
            depthMinMaxTilePerCam.at(batchCamIndex).at(tile.id) = sgmDepthList.getMinMaxDepths();

            // log debug camera / depth information
            sgmDepthList.logRcTcDepthInformation();

            // check if starting and stopping depth are valid
            sgmDepthList.checkStartingAndStoppingDepth();

            // compute Semi-Global Matching
            Sgm* sgm = sgmPerStream.at(i).get();
            sgm->sgmRc(tile, sgmDepthList);

            if (_depthMapParams.useRefine)
            {
                // smooth SGM thickness map
                // in order to be a proper Refine input parameter
                sgm->smoothThicknessMap(tile, _refineParams);

                // compute Refine
                Refine* refine = refinePerStream.at(i).get();
                refine->refineRc(tile, sgm->getDeviceDepthThicknessMap(), sgm->getDeviceNormalMap());

                // copy Refine depth/similarity map from device to host
                tileDepthSimMap_hmh->copyFromOtherBuffer(*refine->getDeviceDepthSimMap());
            }
            else
            {
                // copy Sgm depth/similarity map from device to host
                tileDepthSimMap_hmh->copyFromOtherBuffer(*sgm->getDeviceDepthSimMap());
            }

            // Free device resources early
            sgmPerStream.at(i).reset(nullptr);
            if (_depthMapParams.useRefine)
                refinePerStream.at(i).reset(nullptr);
        }

        // find first and last tile R camera
        const int firstRc = tiles.at(firstTileIndex).rc;
        int lastRc = tiles.at(lastTileIndex - 1).rc;

        // check if last tile depth map is finished
        if (lastTileIndex < tiles.size() && (tiles.at(lastTileIndex).rc == lastRc))
            --lastRc;

        // write depth/sim map result
        for (int c = firstRc; c <= lastRc; ++c)
        {
            const int batchCamIndex = c % nbRcPerBatch;

            if (_depthMapParams.useRefine)
                writeDepthSimMapFromTileList(
                  c, _mp, _tileParams, _tileRoiList, depthSimMapTilePerCam.at(batchCamIndex), _refineParams.scale, _refineParams.stepXY);
            else
                writeDepthSimMapFromTileList(
                  c, _mp, _tileParams, _tileRoiList, depthSimMapTilePerCam.at(batchCamIndex), _sgmParams.scale, _sgmParams.stepXY);

            if (_depthMapParams.exportTilePattern)
                exportDepthSimMapTilePatternObj(c, _mp, _tileRoiList, depthMinMaxTilePerCam.at(batchCamIndex));
        }
    }

    // merge intermediate results tiles if needed and desired
    if (tiles.size() > cams.size())
    {
        // merge tiles if needed and desired
        for (int rc : cams)
        {
            if (_sgmParams.exportIntermediateDepthSimMaps)
            {
                mergeDepthSimMapTiles(rc, _mp, _sgmParams.scale, _sgmParams.stepXY, "sgm");
            }

            if (_sgmParams.exportIntermediateNormalMaps)
            {
                mergeNormalMapTiles(rc, _mp, _sgmParams.scale, _sgmParams.stepXY, "sgm");
            }

            if (_depthMapParams.useRefine)
            {
                if (_refineParams.exportIntermediateDepthSimMaps)
                {
                    mergeDepthPixSizeMapTiles(rc, _mp, _refineParams.scale, _refineParams.stepXY, "sgmUpscaled");
                    mergeDepthSimMapTiles(rc, _mp, _refineParams.scale, _refineParams.stepXY, "refinedFused");
                }

                if (_refineParams.exportIntermediateNormalMaps)
                {
                    mergeNormalMapTiles(rc, _mp, _refineParams.scale, _refineParams.stepXY, "refinedFused");
                    mergeNormalMapTiles(rc, _mp, _refineParams.scale, _refineParams.stepXY);
                }
            }
        }
    }

    // some objects contains CUDA objects
    // this objects should be destroyed before the end of the program (i.e. the end of the CUDA context)
    deviceCache.clearCache();
    sgmPerStream.clear();
    refinePerStream.clear();
}

}  // namespace aliceVision::depthMap::mtl
