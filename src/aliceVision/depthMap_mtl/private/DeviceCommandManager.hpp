// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains a class handling Metal device command management
 *
 * Implementation notes:
 *
 * The member functions of DeviceCommandManager can roughly be divided into
 * three groups:
 *
 * (1) Functions with get*(): These functions retrieve a member variable
 * (2) Functions with new*(): These functions create a new instance in the
 *     command chain, potentially overwriting a previous value if it was not
 *     yet finalized.
 * (3) Functions with set*(): Sets data and/or information for the current
 *     command chain, operating on the currently active states (command
 *     buffers, command encoders).
 */

#pragma once

#include <aliceVision/depthMap_mtl/Concepts.hpp>

#include <unordered_map>
#include <unordered_set>
#include <string>
#include <vector>

#import <Foundation/NSSet.h>
#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLComputePipeline.h>
#import <Metal/MTLDevice.h>

namespace aliceVision::depthMap::mtl {

class DeviceCommandManager final
{
    /* Make DeviceManager a friend, so it can call the private constructor */
    friend class DeviceManager;

  public:
    /* No default constructor */
    DeviceCommandManager() = delete;

    /* No copy/move constructors */
    DeviceCommandManager(const DeviceCommandManager&) = delete;
    DeviceCommandManager(const DeviceCommandManager&&) = delete;
    DeviceCommandManager operator=(const DeviceCommandManager&) = delete;
    DeviceCommandManager operator=(const DeviceCommandManager&&) = delete;

    /**
     * @brief Prefetches and precompiles the requested MTLPipelineStates
     *
     * @param[in] pipelinesToFetch The names for the kernel entry functions
     * @param[in] fromLibraryWithName The name of the Metal library to load the
     *            MTLFunction(s) from
     *
     * @throws A runtime exceptions if the library cannot be found, one of the
     *         kernel entry functions does not exist or pipeline state creation
     *         failed.
     *
     * @note Functions, which require specialization with function constants,
     *       are skipped with a warning and will not be precompiled.
     *
     * @note This function should be called early in the application's
     *       lifespan if any kernel functions are known already. This is due to
     *       the fact that pipeline state creation is a costly process.
     */
    void preloadPipelineStates(const std::vector<const char*>& pipelinesToFetch, const std::string& fromLibraryWithName);

    /**
     * @brief Returns the MTLCommandQueue for this device
     *
     * @returns The strong id<MTLCommandQueue> for this device
     */
    id<MTLCommandQueue> getCMDQueue();

    /**
     * @brief Creates a new MTLCommandBuffer in the current command queue and
     *        sets it as the currently active MTLCommandBuffer
     *
     * @returns Self for easy method chaining
     */
    DeviceCommandManager& newCMDBuffer();

    /**
     * @brief Creates a new MTLComputeCommandEncoder in the current command
     *        queue and sets it as the currently active
     *        MTLComputeCommandEncoder
     *
     * @throws A runtime exception if no command buffer is currently active
     *
     * @returns Self for easy method chaining
     */
    DeviceCommandManager& newCommandEncoder();

    /**
     * @brief Sets the pipeline state identified by its name for the current
     *        MTLComputeCommandEncoder
     *
     * @throws A runtime exception if no compute command encoder is currently
     *         active or if the pipeline identified by the name cannot be
     *         found in cache or the passed library.
     *
     * @param[in] pipelineName The name of the entry point kernel
     * @param[in] fromLibrary (OPTIONAL) An additional MTLLibrary which should
     *            be used additionally to the internally cached pipeline
     *            states.
     *
     * @returns Self for easy method chaining
     */
    DeviceCommandManager& setPipelineState(const std::string& pipelineName, id<MTLLibrary> fromLibrary = nullptr);

    /**
     * @brief Sets an MTLResource for the current MTLCommandEncoder at the
     *        specified binding index
     *
     * @param[in] resource The non-null MTLResource (MTLBuffer / MTLTexture)
     * @param[in] index The binding index to bind this resource to*
     *
     * @throws A runtime exception if no compute command encoder is currently
     *         active.
     *
     * @note Metal distinguishes between MTLBuffers and MTLTextures regarding
     *       the binding indices, i.e., buffers and textures do not share the
     *       same index count.
     *
     * @returns Self for easy method chaining
     */
    DeviceCommandManager& setResource(id<MTLResource> resource, unsigned long index);

    /**
     * @brief Sets push constants for the current MTLComputeCommandEncoder
     *
     * @tparam T The type of push constants, which must comply with the
     *         MTLPushConstantSafe concept
     *
     * @param[in] data The data to pass as push constants
     * @param[in] index The index to bind the push constants to, default to 30
     *
     * @throws A runtime exception if no compute command encoder is currently
     *         active.
     *
     * @note The passed data must comply with the MTLPushConstantSafe concept,
     *       i.e., be POD and smaller than 4096 bytes.
     *       For simplicity the index for binding the push constants defaults
     *       to 30 (which is the last index for MTLBuffers).
     *
     * @returns Self for easy method chaining
     */
    template<MTLPushConstantSafe T>
    DeviceCommandManager& setPushConstants(T data, unsigned long index = 30);

    /**
     * @brief Sets push constants for the current MTLComputeCommandEncoder
     *
     * @tparam T The type of push constants, which must comply with the
     *         MTLPushConstantSafe concept
     *
     * @param[in] data The data to pass as push constants
     * @param[in] index The index to bind the push constants to, default to 30
     *
     * @throws A runtime exception if no compute command encoder is currently
     *         active.
     *
     * @note The passed data must comply with the MTLPushConstantSafe concept,
     *       i.e., be POD and smaller than 4096 bytes.
     *       For simplicity the index for binding the push constants defaults
     *       to 30 (which is the last index for MTLBuffers).
     *
     * @returns Self for easy method chaining
     */
    template<MTLArrayPushConstantSafe T>
    DeviceCommandManager& setPushConstantsArray(T data, unsigned long index = 30);

    /**
     * @brief Sets the dispatch dimensions for the current
     *        MTLComputeCommandEncoder
     *
     * @param[in] threadsPerGrid The total count of threads required to execute
     * @param[in] threadsPerThreadgroup The count of threads per threadgroup
     *
     * @throws A runtime exception if no compute command encoder is currently
     *         active.
     *
     * @returns Self for easy method chaining
     */
    DeviceCommandManager& setDispatchDimensions(const MTLSize& threadsPerGrid, const MTLSize& threadsPerThreadgroup);

    /**
     * @brief Sets the dispatch dimensions for the current
     *        MTLComputeCommandEncoder and calculates the optimal size of
     *        the threadgroups to use
     *
     * @param[in] threadsPerGrid The total count of threads required to execute
     *
     * @throws A runtime exception if no compute command encoder is currently
     *         active.
     *
     * @returns Self for easy method chaining
     */
    DeviceCommandManager& setDispatchDimensionsWithAutomaticThreadgroupSize(const MTLSize& threadsPerGrid);

    /**
     * @brief Finished the currently active command encoder and ends its
     *        encoding
     *
     * @note The underlying MTLComputeCommandEncoder cannot be used anymore
     *       (it is finalized).
     *
     * @returns Self for easy method chaining
     */
    DeviceCommandManager& finishCommandEncoder();

    /**
     * @brief Finished the currently active command buffer, ends recording into
     *        it and enqueues/commits it to the command queue
     *
     * @note The underlying MTLCommandBuffer cannot be used anymore (it is
     *       finalized).
     *
     * @note The returned MTLCommandBuffer can be awaited using waitForFinish,
     *       although it will be executed no matter if explicitly awaited or
     *       not.
     *
     * @returns The finalized and commited MTLCommandBuffer
     */
    id<MTLCommandBuffer> finishCommandBuffer();

    /**
     * @brief Waits for the passed MTLCommandBuffer to finish executing on
     *        the Metal device
     *
     * @note If the buffer already completed its execution, this function is
     *       a no-op.
     */
    void waitForFinish(id<MTLCommandBuffer> theBuffer);

  private:
    /**
     * @brief Private constructor which associates the instance to be created
     *        with the specified MTLDevice
     *
     * This constructor is private and should only be called by the friend
     * class DeviceManager.
     */
    explicit DeviceCommandManager(id<MTLDevice> dev);

    const __strong id<MTLDevice> _dev;  //< The associated device

    __strong id<MTLCommandQueue> _queue;  //< The MTLCommandQueue for this device, thread safe

    std::unordered_map<std::string, __strong id<MTLComputePipelineState>>
      _pipelineStateCache;  //< A cache of MTLPipelineStates, identified by their name

    __strong id<MTLCommandBuffer> _currentCMDBuffer;               //< The current MTLCommandBuffer, nullptr if none
    __strong id<MTLComputeCommandEncoder> _currentCommandEncoder;  //< The current MTLComputeCommandEncoder, nullptr if null
    __strong id<MTLComputePipelineState> _currentPipelineState;    //< The current MTLComputePipelineState, nullptr if null
    NSMutableSet<id<MTLCommandBuffer>>* _cmdBuffersInFlight;       //< All MTLCommandBuffers which are currently in flight
};

}  // namespace aliceVision::depthMap::mtl

/* clang-format off */
// Include the inline definitions
#ifndef DEVICE_COMMAND_MANAGER_INL
#define DEVICE_COMMAND_MANAGER_INL
    #import <aliceVision/depthMap_mtl/private/inline/DeviceCommandManager.inl>
#endif
/* clang-format on */
