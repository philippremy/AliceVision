// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#import <aliceVision/depthMap_mtl/private/ObjectiveCUtils.hpp>

#include <aliceVision/system/Logger.hpp>
#include <aliceVision/config.hpp>

#include <cassert>
#include <cstdlib>
#include <filesystem>

#import <Foundation/NSError.h>
#import <Foundation/NSSet.h>

#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLLibrary.h>

/* clang-format off */
#if ALICEVISION_IS_DEFINED(ALICEVISION_BUNDLED_AS_FRAMEWORKS)
    #import <Foundation/NSBundle.h>
    #import <Foundation/NSObject.h>
    #import <Foundation/NSString.h>
    #import <Foundation/NSURL.h>

    /* Helper Objective-C class for bundle resolution */
    /* Must be in the global namespace, so prefix with namespace */
    @interface __aliceVision__depthMap__mtl__stubclass : NSObject
    @end
    @implementation __aliceVision__depthMap__mtl__stubclass
    @end
#endif
/* clang-format on */

namespace aliceVision::depthMap::mtl {

#pragma mark Private class functions

DeviceCommandManager::DeviceCommandManager(id<MTLDevice> dev)
  : _dev(dev)
{
    // Create an MTLCommandQueue
    this->_queue = [this->_dev newCommandQueueWithMaxCommandBufferCount:64];
    if (!this->_queue)
        ALICEVISION_THROW_ERROR("Creating an MTLCommandQueue for device " << [this->_dev registryID] << " failed!");

    // Create the mutable set
    this->_cmdBuffersInFlight = [NSMutableSet new];
}

void DeviceCommandManager::preloadPipelineStates(const std::vector<const char*>& pipelinesToFetch, const std::string& fromLibraryWithName)
{
    // MTLLibrary, initially a nullptr
    id<MTLLibrary> metalLib = nullptr;

    // Find the MTLLibrary
    // (1) If compiled as Framework, use NSBundle
    // (2) $ALICEVISION_ROOT/share/<NAME>.metallib

    /* clang-format off */
    #if ALICEVISION_IS_DEFINED(ALICEVISION_BUNDLED_AS_FRAMEWORKS)
    {
        // This is guaranteed to resolve to a bundle if the class is non-null
        NSBundle* frameworkBundle = [NSBundle bundleForClass:[__aliceVision__depthMap__mtl__stubclass class]];
        NSURL* resourceURL = [frameworkBundle URLForResource:nsstring_from_string(fromLibraryWithName) withExtension:@"metallib"];
        if (!resourceURL)
            ALICEVISION_THROW_ERROR("Metal library with name " << fromLibraryWithName << " not found in this Framework!");

        NSError* libraryLoadingError = nullptr;
        metalLib = [this->_dev newLibraryWithURL:resourceURL error:&libraryLoadingError];
        if (!metalLib)
        {
            if (libraryLoadingError)
            {
                ALICEVISION_THROW_ERROR("Failed to load MTLLibrary from URL "
                                        << string_from_nsurl(resourceURL)
                                        << ", error: " << string_from_nsstring([libraryLoadingError localizedDescription]) << "!");
            }
            else
            {
                ALICEVISION_THROW_ERROR("Failed to load MTLLibrary from URL " << string_from_nsurl(resourceURL) << ", error: No error description.");
            }
        }
    }
    #endif
    /* clang-format on */

    // If the MTLLibrary is still a nullptr, attempt resolving using
    // $ALICEVISION_ROOT
    if (!metalLib)
    {
        const char* aliceVisionRoot = std::getenv("ALICEVISION_ROOT");
        if (!aliceVisionRoot)
            ALICEVISION_THROW_ERROR("ALICEVISION_ROOT is not set in the environment!");

        std::filesystem::path aliceVisionRootPath = std::filesystem::path(aliceVisionRoot);
        std::filesystem::path resourcePath = aliceVisionRootPath / "share" / (fromLibraryWithName + ".metallib");
        if (!std::filesystem::exists(resourcePath))
            ALICEVISION_THROW_ERROR("The requested Metal library does not exist at " << resourcePath << "!");

        NSError* libraryLoadingError = nullptr;
        metalLib = [this->_dev newLibraryWithURL:nsurl_from_string(resourcePath.string()) error:&libraryLoadingError];
        if (!metalLib)
        {
            if (libraryLoadingError)
            {
                ALICEVISION_THROW_ERROR("Failed to create MTLLibrary from path "
                                        << resourcePath << ", error: " << string_from_nsstring([libraryLoadingError localizedDescription]) << "!");
            }
            else
            {
                ALICEVISION_THROW_ERROR("Failed to create MTLLibrary from path " << resourcePath << ", error: No error description.");
            }
        }
    }

    // We must have a valid MTLLibrary at this point
    assert(metalLib != nullptr && "The Metal Library *must* be resolved at this point!");

    // Iterate each requested kernel entry name and try to create a pipeline state from it
    for (const char* kernelName : pipelinesToFetch)
    {
        // Attempt to find the kernel function in the MTLLibrary
        id<MTLFunction> metalFunc = [metalLib newFunctionWithName:nsstring_from_const_char_ptr(kernelName)];
        if (!metalFunc)
            ALICEVISION_THROW_ERROR("No Metal kernel entry function with name " << kernelName << " was found in the MTLLibrary with name "
                                                                                << fromLibraryWithName << "!");

        // Check if this kernel requires function constants, in which case it
        // cannot be precompiled
        if ([[metalFunc functionConstantsDictionary] count] != 0)
        {
            ALICEVISION_LOG_WARNING("The MTLFunction with name "
                                    << kernelName
                                    << " requires specialization with function constants and cannot be used for precompilation. Skipping...");
            continue;
        }

        // Now create the compute pipeline state
        NSError* pipelineCreationError = nullptr;
        id<MTLComputePipelineState> pipelineState = [this->_dev newComputePipelineStateWithFunction:metalFunc error:&pipelineCreationError];
        if (!pipelineState)
        {
            if (pipelineCreationError)
            {
                ALICEVISION_THROW_ERROR("Failed to create MTLComputePipelineState from MTLFunction "
                                        << kernelName << ", error: " << string_from_nsstring([pipelineCreationError localizedDescription]) << "!");
            }
            else
            {
                ALICEVISION_THROW_ERROR("Failed to create MTLComputePipelineState from MTLFunction " << kernelName
                                                                                                     << ", error: No error description.");
            }
        }

        // Append it to the internal cache
        this->_pipelineStateCache.emplace(kernelName, pipelineState);
    }
}

id<MTLCommandQueue> DeviceCommandManager::getCMDQueue() { return this->_queue; }

DeviceCommandManager& DeviceCommandManager::newCMDBuffer()
{
    this->_currentCMDBuffer = [this->_queue commandBuffer];
    if (!this->_currentCMDBuffer)
        ALICEVISION_THROW_ERROR("Failed to create a new MTLCommandBuffer for MTLDevice " << [this->_dev registryID]);

    return *this;
}

DeviceCommandManager& DeviceCommandManager::newCommandEncoder()
{
    if (!this->_currentCMDBuffer)
        ALICEVISION_THROW_ERROR("Cannot create a MTLComputeCommandEncoder without an active MTLCommandBuffer!");

    this->_currentCommandEncoder = [this->_currentCMDBuffer computeCommandEncoder];

    if (!this->_currentCMDBuffer)
        ALICEVISION_THROW_ERROR("Failed to create a new MTLComputeCommandEncoder for MTLDevice " << [this->_dev registryID]);

    return *this;
}

DeviceCommandManager& DeviceCommandManager::setPipelineState(const std::string& pipelineName, id<MTLLibrary> fromLibrary)
{
    if (!this->_currentCommandEncoder)
        ALICEVISION_THROW_ERROR("Cannot set the MTLPipelineState without an active MTLComputeCommandEncoder!");

    if (this->_pipelineStateCache.contains(pipelineName))
    {
        [this->_currentCommandEncoder setComputePipelineState:this->_pipelineStateCache.at(pipelineName)];
        this->_currentPipelineState = this->_pipelineStateCache.at(pipelineName);
        return *this;
    }

    if (fromLibrary)
    {
        bool noSpecializationRequired = true;

        // Attempt to find the kernel function in the MTLLibrary
        id<MTLFunction> metalFunc = [fromLibrary newFunctionWithName:nsstring_from_string(pipelineName)];
        if (!metalFunc)
            ALICEVISION_THROW_ERROR("No Metal kernel entry function with name " << pipelineName << " was found in the MTLLibrary with name "
                                                                                << fromLibrary << "!");

        // Check if this kernel requires function constants, in which case it
        // cannot be precompiled
        if ([[metalFunc functionConstantsDictionary] count] != 0)
        {
            noSpecializationRequired = false;
        }

        // Now create the compute pipeline state
        NSError* pipelineCreationError = nullptr;
        id<MTLComputePipelineState> pipelineState = [this->_dev newComputePipelineStateWithFunction:metalFunc error:&pipelineCreationError];
        if (!pipelineState)
        {
            if (pipelineCreationError)
            {
                ALICEVISION_THROW_ERROR("Failed to create MTLComputePipelineState from MTLFunction "
                                        << pipelineName << ", error: " << string_from_nsstring([pipelineCreationError localizedDescription]) << "!");
            }
            else
            {
                ALICEVISION_THROW_ERROR("Failed to create MTLComputePipelineState from MTLFunction " << pipelineName
                                                                                                     << ", error: No error description.");
            }
        }

        // Append it to the internal cache if no specialization was required
        if (noSpecializationRequired)
            this->_pipelineStateCache.emplace(pipelineName, pipelineState);

        // Set it to the current command encoder
        [this->_currentCommandEncoder setComputePipelineState:pipelineState];
        this->_currentPipelineState = pipelineState;

        return *this;
    }

    ALICEVISION_THROW_ERROR("Pipeline with name " << pipelineName
                                                  << " was not found in the preloaded cache and loading via a passed MTLLibrary was not requested!");
}

DeviceCommandManager& DeviceCommandManager::setResource(id<MTLResource> resource, unsigned long index)
{
    if (!this->_currentCommandEncoder)
        ALICEVISION_THROW_ERROR("Cannot set an MTLResource without an active MTLComputeCommandEncoder!");

    // Switch on the concrete type of resource
    if ([resource conformsToProtocol:@protocol(MTLBuffer)])
    {
        [this->_currentCommandEncoder setBuffer:static_cast<id<MTLBuffer>>(resource) offset:0 atIndex:index];
    }
    else if ([resource conformsToProtocol:@protocol(MTLTexture)])
    {
        [this->_currentCommandEncoder setTexture:static_cast<id<MTLTexture>>(resource) atIndex:index];
    }
    else
    {
        ALICEVISION_THROW_ERROR("Resource " << resource << " did not conform to either MTLBuffer or MTLTexture!");
    }

    return *this;
}

DeviceCommandManager& DeviceCommandManager::setDispatchDimensions(const MTLSize& threadsPerGrid, const MTLSize& threadsPerThreadgroup)
{
    if (!this->_currentCommandEncoder)
        ALICEVISION_THROW_ERROR("Cannot set the dispatch dimensions without an active MTLComputeCommandEncoder!");

    [this->_currentCommandEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];

    return *this;
}

DeviceCommandManager& DeviceCommandManager::setDispatchDimensionsWithAutomaticThreadgroupSize(const MTLSize& threadsPerGrid)
{
    // See the Apple Info Page for this:
    // https://developer.apple.com/documentation/metal/calculating-threadgroup-and-grid-sizes
    //
    // We will query the following:
    // (1) The maximum count of threads that a single threadgroup can have
    // (2) The thread execution width, which is the count of threads that
    //     execute simultaneously

    if (!this->_currentCommandEncoder)
        ALICEVISION_THROW_ERROR("Cannot set the dispatch dimensions without an active MTLComputeCommandEncoder!");

    if (!this->_currentPipelineState)
        ALICEVISION_THROW_ERROR("Cannot set the dispatch dimensions without an active MTLComputePipelineState!");

    uint64_t maxTotalThreadsPerThreadgroup = [this->_currentPipelineState maxTotalThreadsPerThreadgroup];
    uint64_t threadExecutionWidth = [this->_currentPipelineState threadExecutionWidth];
    uint64_t heightCalc = maxTotalThreadsPerThreadgroup / threadExecutionWidth;

    MTLSize threadsPerThreadgroup = MTLSizeMake(threadExecutionWidth, heightCalc, 1);

    [this->_currentCommandEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];

    return *this;
}

DeviceCommandManager& DeviceCommandManager::finishCommandEncoder()
{
    if (!this->_currentCommandEncoder)
        ALICEVISION_THROW_ERROR("Cannot finish an MTLComputeCommandEncoder without an active MTLComputeCommandEncoder!");

    // Reset current pipeline state
    this->_currentPipelineState = nullptr;

    [this->_currentCommandEncoder endEncoding];

    return *this;
}

id<MTLCommandBuffer> DeviceCommandManager::finishCommandBuffer()
{
    if (!this->_currentCMDBuffer)
        ALICEVISION_THROW_ERROR("Cannot finish an MTLCommandBuffer without an active MTLCommandBuffer!");

    // Add to internal queue
    [this->_cmdBuffersInFlight addObject:this->_currentCMDBuffer];

    // Set complete handler (remove self from internal queue)
    // We *cannot* capture "this", because it could technically go out of scope
    // and cause a UAF. Instead, we rely on "fetching" the appropriate
    // DeviceCommandManager "again" here.
    // This block must not capture any variables from the outer scope, because
    // we cannot control when this completion handler will be run.
    [this->_currentCMDBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull finishedCMDBuf) {
      const id<MTLDevice> dev = [finishedCMDBuf device];
      if ([finishedCMDBuf error])
          ALICEVISION_LOG_ERROR("MTLCommandBuffer " << finishedCMDBuf
                                                    << " returned an error: " << string_from_nsstring([[finishedCMDBuf error] localizedDescription]));
      [DeviceManager::instance().getCMDManager(dev)._cmdBuffersInFlight removeObject:finishedCMDBuf];
    }];

    // Commit to device
    [this->_currentCMDBuffer commit];

    // Return MTLCommandBuffer
    return this->_currentCMDBuffer;
}

void DeviceCommandManager::waitForFinish(id<MTLCommandBuffer> theBuffer) { [theBuffer waitUntilCompleted]; }

}  // namespace aliceVision::depthMap::mtl
