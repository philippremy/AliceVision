// This file is part of the AliceVision project.
// Copyright (c) 2022, 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#include <aliceVision/depthMap_mtl/VolumeIO.hpp>

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/RefineParams.hpp>
#include <aliceVision/depthMap_mtl/SgmParams.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/image/jetColorMap.hpp>
#include <aliceVision/mvsData/geometry.hpp>
#include <aliceVision/mvsData/ROI.hpp>
#include <aliceVision/mvsUtils/MultiViewParams.hpp>
#include <aliceVision/sfmData/SfMData.hpp>
#include <aliceVision/sfmDataIO/sfmDataIO.hpp>

#include <memory>
#include <string>
#include <vector>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

namespace aliceVision::depthMap::mtl {

void exportSimilarityVolume(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                            const std::vector<float>& in_depths,
                            const mvsUtils::MultiViewParams& mp,
                            int camIndex,
                            const SgmParams& sgmParams,
                            const std::string& filepath,
                            const ROI& roi)
{
    sfmData::SfMData pointCloud;
    const int xyStep = 10;

    IndexT landmarkId;

    // No padding in MTLBuffers!
    const MTLResourceSize<3> volDim = in_volumeSim_hmh->getSize();

    in_volumeSim_hmh->readOnHost([&](const std::mdspan<const TSim, std::dextents<size_t, 3>> contents) {
        for (size_t vy = 0; vy < volDim.height(); vy += xyStep)
        {
            for (size_t vx = 0; vx < volDim.width(); vx += xyStep)
            {
                const double x = roi.x.begin + (vx * sgmParams.scale * sgmParams.stepXY);
                const double y = roi.y.begin + (vy * sgmParams.scale * sgmParams.stepXY);

                for (size_t vz = 0; vz < in_depths.size(); ++vz)
                {
                    const double planeDepth = in_depths[vz];
                    const Point3d planen = (mp.iRArr[camIndex] * Point3d(0.0f, 0.0f, 1.0f)).normalize();
                    const Point3d planep = mp.CArr[camIndex] + planen * planeDepth;
                    const Point3d v = (mp.iCamArr[camIndex] * Point2d(x, y)).normalize();
                    const Point3d p = linePlaneIntersect(mp.CArr[camIndex], v, planep, planen);

                    const float maxValue = 80.f;
                    float simValue = contents[vz, vy, vx];
                    if (simValue > maxValue)
                        continue;
                    const rgb c = getRGBFromJetColorMap(simValue / maxValue);
                    pointCloud.getLandmarks()[landmarkId] =
                      sfmData::Landmark(Vec3(p.x, p.y, p.z), feature::EImageDescriberType::UNKNOWN, image::RGBColor(c.r, c.g, c.b));

                    ++landmarkId;
                }
            }
        }
    });

    sfmDataIO::save(pointCloud, filepath, sfmDataIO::ESfMData::STRUCTURE);
}

void exportSimilarityVolumeCross(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                 const std::vector<float>& in_depths,
                                 const mvsUtils::MultiViewParams& mp,
                                 int camIndex,
                                 const SgmParams& sgmParams,
                                 const std::string& filepath,
                                 const ROI& roi)
{
    sfmData::SfMData pointCloud;

    IndexT landmarkId;

    // No padding in MTLBuffers!
    const MTLResourceSize<3> volDim = in_volumeSim_hmh->getSize();

    in_volumeSim_hmh->readOnHost([&](const std::mdspan<const TSim, std::dextents<size_t, 3>> contents) {
        for (size_t vz = 0; vz < in_depths.size(); ++vz)
        {
            for (size_t vy = 0; vy < volDim.height(); ++vy)
            {
                const bool vyCenter = (vy >= volDim.height() / 2) && ((vy - 1) < volDim.height() / 2);
                const size_t xIdxStart = (vyCenter ? 0 : (volDim.width() / 2));
                const size_t xIdxStop = (vyCenter ? volDim.width() : (xIdxStart + 1));

                for (size_t vx = xIdxStart; vx < xIdxStop; ++vx)
                {
                    const double x = roi.x.begin + (vx * sgmParams.scale * sgmParams.stepXY);
                    const double y = roi.y.begin + (vy * sgmParams.scale * sgmParams.stepXY);
                    const double planeDepth = in_depths[vz];
                    const Point3d planen = (mp.iRArr[camIndex] * Point3d(0.0f, 0.0f, 1.0f)).normalize();
                    const Point3d planep = mp.CArr[camIndex] + planen * planeDepth;
                    const Point3d v = (mp.iCamArr[camIndex] * Point2d(x, y)).normalize();
                    const Point3d p = linePlaneIntersect(mp.CArr[camIndex], v, planep, planen);

                    const float maxValue = 80.f;
                    float simValue = contents[vz, vy, vx];

                    if (simValue > maxValue)
                        continue;

                    const rgb c = getRGBFromJetColorMap(simValue / maxValue);
                    pointCloud.getLandmarks()[landmarkId] =
                      sfmData::Landmark(Vec3(p.x, p.y, p.z), feature::EImageDescriberType::UNKNOWN, image::RGBColor(c.r, c.g, c.b));

                    ++landmarkId;
                }
            }
        }
    });

    sfmDataIO::save(pointCloud, filepath, sfmDataIO::ESfMData::STRUCTURE);
}

void exportSimilarityVolumeTopographicCut(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                          const std::vector<float>& in_depths,
                                          const mvsUtils::MultiViewParams& mp,
                                          int camIndex,
                                          const SgmParams& sgmParams,
                                          const std::string& filepath,
                                          const ROI& roi)
{
    sfmData::SfMData pointCloud;

    const MTLResourceSize<3> volDim = in_volumeSim_hmh->getSize();
    const size_t vy = size_t(divideRoundUp(int(volDim.height()), 2));  // center only

    const Point3d planen = (mp.iRArr[camIndex] * Point3d(0.0f, 0.0f, 1.0f)).normalize();

    // compute min and max similarity values
    float minSim = std::numeric_limits<float>::max();
    float maxSim = std::numeric_limits<float>::min();

    in_volumeSim_hmh->readOnHost([&](const std::mdspan<const TSim, std::dextents<size_t, 3>> contents) {
        for (size_t vx = 0; vx < volDim.width(); ++vx)
        {
            for (size_t vz = 0; vz < volDim.depth(); ++vz)
            {
                const float simValue = contents[vz, vy, vx];

                if (simValue > 254.f)  // invalid similarity
                    continue;

                maxSim = std::max(maxSim, simValue);
                minSim = std::min(minSim, simValue);
            }
        }

        const float simNorm = (maxSim == minSim) ? 0.f : (1.f / (maxSim - minSim));

        // compute each point color and position
        IndexT landmarkId = 0;

        for (size_t vx = 0; vx < volDim.width(); ++vx)
        {
            const double x = roi.x.begin + (vx * sgmParams.scale * sgmParams.stepXY);
            const double y = roi.y.begin + (vy * sgmParams.scale * sgmParams.stepXY);
            const Point2d pix(x, y);

            for (size_t vz = 0; vz < in_depths.size(); ++vz)
            {
                const float simValue = contents[vz, vy, vx];

                if (simValue > 254.f)  // invalid similarity
                    continue;

                const float simValueNorm = (simValue - minSim) * simNorm;

                const double planeDepth = in_depths[vz];
                const Point3d planep = mp.CArr[camIndex] + planen * planeDepth;
                const Point3d v = (mp.iCamArr[camIndex] * (pix + Point2d(0.0, simValueNorm * 15.0))).normalize();
                const Point3d p = linePlaneIntersect(mp.CArr[camIndex], v, planep, planen);

                const rgb c = getRGBFromJetColorMap(simValueNorm);
                pointCloud.getLandmarks()[landmarkId] =
                  sfmData::Landmark(Vec3(p.x, p.y, p.z), feature::EImageDescriberType::UNKNOWN, image::RGBColor(c.r, c.g, c.b));

                ++landmarkId;
            }
        }
    });

    // write point cloud
    sfmDataIO::save(pointCloud, filepath, sfmDataIO::ESfMData::STRUCTURE);
}

void exportSimilaritySamplesCSV(const std::unique_ptr<MTLDeviceMemory<TSim, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                const std::vector<float>& in_depths,
                                const std::string& name,
                                const SgmParams& sgmParams,
                                const std::string& filepath,
                                const ROI& roi)
{
    const ROI downscaledRoi = downscaleROI(roi, sgmParams.scale * sgmParams.stepXY);

    const int sampleSize = 3;

    const int xOffset = std::floor(downscaledRoi.width() / (sampleSize + 1.0f));
    const int yOffset = std::floor(downscaledRoi.height() / (sampleSize + 1.0f));

    std::vector<Point2d> ptsCoords(sampleSize * sampleSize);
    std::vector<std::vector<float>> ptsDepths(sampleSize * sampleSize);

    in_volumeSim_hmh->readOnHost([&](const std::mdspan<const TSim, std::dextents<size_t, 3>> contents) {
        for (int iy = 0; iy < sampleSize; ++iy)
        {
            for (int ix = 0; ix < sampleSize; ++ix)
            {
                const int ptIdx = iy * sampleSize + ix;
                const int x = (ix + 1) * xOffset;
                const int y = (iy + 1) * yOffset;

                ptsCoords.at(ptIdx) = {x, y};
                std::vector<float>& pDepths = ptsDepths.at(ptIdx);

                pDepths.reserve(in_depths.size());

                for (size_t iz = 0; iz < in_depths.size(); ++iz)
                {
                    const float simValue = contents[iz, y, x];
                    pDepths.push_back(simValue);
                }
            }
        }
    });

    std::stringstream ss;

    ss << name << "\n";

    for (size_t i = 0; i < ptsCoords.size(); ++i)
    {
        const Point2d& coord = ptsCoords.at(i);
        ss << "p" << (i + 1) << " (x: " << coord.x << ", y: " << coord.y << ");";
        for (const float depth : ptsDepths.at(i))
            ss << depth << ";";
        ss << "\n";
    }

    std::ofstream file;
    file.open(filepath, std::ios_base::app);
    if (file.is_open())
        file << ss.str();
}

void exportSimilarityVolumeCross(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                 const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>& in_depthSimMapSgmUpscale_hmh,
                                 const mvsUtils::MultiViewParams& mp,
                                 int camIndex,
                                 const RefineParams& refineParams,
                                 const std::string& filepath,
                                 const ROI& roi)
{
    sfmData::SfMData pointCloud;

    const auto volDim = in_volumeSim_hmh->getSize();

    IndexT landmarkId = 0;

    in_volumeSim_hmh->readOnHost([&](const std::mdspan<const TSimRefine, std::dextents<size_t, 3>> contents) {
        for (int vy = 0; vy < volDim.height(); ++vy)
        {
            const bool vyCenter = ((vy * 2) == volDim.height());
            const int xIdxStart = (vyCenter ? 0 : (volDim.width() / 2));
            const int xIdxStop = (vyCenter ? volDim.width() : (xIdxStart + 1));

            for (int vx = xIdxStart; vx < xIdxStop; ++vx)
            {
                const int x = roi.x.begin + (double(vx) * refineParams.scale * refineParams.stepXY);
                const int y = roi.y.begin + (double(vy) * refineParams.scale * refineParams.stepXY);
                const Point2d pix(x, y);

                /* FIXME: This might be expensive to do in a loop, maybe cache
                          beforehand?
                */
                float2 depthPixSizeMap = {};
                in_depthSimMapSgmUpscale_hmh->readOnHost(
                  [&](const std::mdspan<const float2, std::dextents<size_t, 2>> contentsInner) { depthPixSizeMap = contentsInner[vy, vx]; });

                if (depthPixSizeMap.x < 0.0f)  // original depth invalid or masked
                    continue;

                for (int vz = 0; vz < volDim.depth(); ++vz)
                {
                    const float simValue = contents[vz, vy, vx];

                    const float maxValue = 10.f;  // sum of similarity between 0 and 1
                    if (simValue > maxValue)
                        continue;

                    const int relativeDepthIndexOffset = vz - refineParams.halfNbDepths;
                    const double depth =
                      depthPixSizeMap.x + (relativeDepthIndexOffset * depthPixSizeMap.y);  // original depth + z based pixSize offset

                    const Point3d p = mp.CArr[camIndex] + (mp.iCamArr[camIndex] * pix).normalize() * depth;

                    const rgb c = getRGBFromJetColorMap(simValue / maxValue);
                    pointCloud.getLandmarks()[landmarkId] =
                      sfmData::Landmark(Vec3(p.x, p.y, p.z), feature::EImageDescriberType::UNKNOWN, image::RGBColor(c.r, c.g, c.b));

                    ++landmarkId;
                }
            }
        }
    });

    sfmDataIO::save(pointCloud, filepath, sfmDataIO::ESfMData::STRUCTURE);
}

void exportSimilarityVolumeTopographicCut(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                          const std::unique_ptr<MTLDeviceMemory<float2, 2, MemoryType::HostVisible>>& in_depthSimMapSgmUpscale_hmh,
                                          const mvsUtils::MultiViewParams& mp,
                                          int camIndex,
                                          const RefineParams& refineParams,
                                          const std::string& filepath,
                                          const ROI& roi)
{
    sfmData::SfMData pointCloud;

    const auto volDim = in_volumeSim_hmh->getSize();
    const size_t vy = size_t(divideRoundUp(int(volDim.height()), 2));  // center only

    // compute min and max similarity values
    const float minSim = 0.f;
    float maxSim = std::numeric_limits<float>::epsilon();

    in_volumeSim_hmh->readOnHost([&](std::mdspan<const TSimRefine, std::dextents<size_t, 3>> contents) {
        for (size_t vx = 0; vx < volDim.width(); ++vx)
        {
            for (size_t vz = 0; vz < volDim.depth(); ++vz)
            {
                const float simValue = contents[vz, vy, vx];
                maxSim = std::max(maxSim, simValue);
            }
        }
        // compute each point color and position
        IndexT landmarkId = 0;

        for (size_t vx = 0; vx < volDim.width(); ++vx)
        {
            const double x = roi.x.begin + (vx * refineParams.scale * refineParams.stepXY);
            const double y = roi.y.begin + (vy * refineParams.scale * refineParams.stepXY);
            const Point2d pix(x, y);

            /* FIXME: This might be expensive to do in a loop, maybe cache
                      beforehand?
            */
            float2 depthPixSizeMap = {};
            in_depthSimMapSgmUpscale_hmh->readOnHost(
              [&](std::mdspan<const float2, std::dextents<size_t, 2>> contentsInner) { depthPixSizeMap = contentsInner[vy, vx]; });

            if (depthPixSizeMap.x < 0.0f)  // middle depth (SGM) invalid or masked
                continue;

            for (size_t vz = 0; vz < volDim.depth(); ++vz)
            {
                const float simValue = contents[vz, vy, vx];
                const float simValueNorm = (simValue - minSim) / (maxSim - minSim);
                const float simValueColor = 1 - simValueNorm;  // best similarity value is 0, worst value is 1

                const int relativeDepthIndexOffset = vz - refineParams.halfNbDepths;
                const double depth = depthPixSizeMap.x + (relativeDepthIndexOffset * depthPixSizeMap.y);  // original depth + z based pixSize offset

                const Point3d p = mp.CArr[camIndex] + (mp.iCamArr[camIndex] * (pix + Point2d(0.0, -simValueNorm * 15.0))).normalize() * depth;

                const rgb c = getRGBFromJetColorMap(simValueColor);
                pointCloud.getLandmarks()[landmarkId] =
                  sfmData::Landmark(Vec3(p.x, p.y, p.z), feature::EImageDescriberType::UNKNOWN, image::RGBColor(c.r, c.g, c.b));

                ++landmarkId;
            }
        }
    });

    // write point cloud
    sfmDataIO::save(pointCloud, filepath, sfmDataIO::ESfMData::STRUCTURE);
}

void exportSimilaritySamplesCSV(const std::unique_ptr<MTLDeviceMemory<TSimRefine, 3, MemoryType::HostVisible>>& in_volumeSim_hmh,
                                const std::string& name,
                                const RefineParams& refineParams,
                                const std::string& filepath,
                                const ROI& roi)
{
    const ROI downscaledRoi = downscaleROI(roi, refineParams.scale * refineParams.stepXY);

    const size_t volDimZ = in_volumeSim_hmh->getSize().depth();

    const int sampleSize = 3;

    const int xOffset = std::floor(downscaledRoi.width() / (sampleSize + 1.0f));
    const int yOffset = std::floor(downscaledRoi.height() / (sampleSize + 1.0f));

    std::vector<Point2d> ptsCoords(sampleSize * sampleSize);
    std::vector<std::vector<float>> ptsDepths(sampleSize * sampleSize);

    in_volumeSim_hmh->readOnHost([&](const std::mdspan<const TSimRefine, std::dextents<size_t, 3>> contents) {
        for (int iy = 0; iy < sampleSize; ++iy)
        {
            for (int ix = 0; ix < sampleSize; ++ix)
            {
                const int ptIdx = iy * sampleSize + ix;
                const int x = (ix + 1) * xOffset;
                const int y = (iy + 1) * yOffset;

                ptsCoords.at(ptIdx) = {x, y};
                std::vector<float>& pDepths = ptsDepths.at(ptIdx);

                pDepths.reserve(volDimZ);

                for (int iz = 0; iz < volDimZ; ++iz)
                {
                    const float simValue = contents[iz, y, x];
                    pDepths.push_back(simValue);
                }
            }
        }
    });

    std::stringstream ss;

    ss << name << "\n";

    for (int i = 0; i < ptsCoords.size(); ++i)
    {
        const Point2d& coord = ptsCoords.at(i);
        ss << "p" << (i + 1) << " (x: " << coord.x << ", y: " << coord.y << ");";
        for (const float depth : ptsDepths.at(i))
            ss << depth << ";";
        ss << "\n";
    }

    std::ofstream file;
    file.open(filepath, std::ios_base::app);
    if (file.is_open())
        file << ss.str();
}

}  // namespace aliceVision::depthMap::mtl
