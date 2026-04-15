// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#ifndef MTL_DEVICE_MEMORY_IMPL_INL
    #error This file cannot be included directly, include MTLDeviceMemoryImpl.hpp instead
#endif

#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>

#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/system/Logger.hpp>

#include <cstdint>
#include <functional>
#include <mdspan>
#include <optional>

#import <Metal/MTLBlitCommandEncoder.h>
#import <Metal/MTLBuffer.h>
#import <Metal/MTLCommandBuffer.h>
#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLResource.h>

namespace aliceVision::depthMap::mtl {

#pragma mark Utility Methods

// Checks if the underlying memory type is
// (1) Shared (Apple Silicon)
// (2) Managed (Intel/AMD GPUs)
inline void checkSharedMemoryType(id<MTLDevice> dev, bool& isShared, bool& isManaged)
{
    if ([dev supportsFamily:(MTLGPUFamilyApple1)])
    {
        isShared = true;
        isManaged = false;
    }
    else
    {
        isShared = false;
        isManaged = true;
    }
}

// Ensures that any changes written to a buffer from the GPU are synchronized
// in order to be accessed from the host CPU
inline void synchronizeDeviceMemory(id<MTLDevice> dev, id<MTLResource> theResource)
{
    id<MTLCommandQueue> cmdQueue = DeviceManager::instance().getCMDManager(dev).getCMDQueue();
    id<MTLCommandBuffer> cmdBuffer = [cmdQueue commandBuffer];
    id<MTLBlitCommandEncoder> blitEncoder = [cmdBuffer blitCommandEncoder];
    [blitEncoder synchronizeResource:theResource];
    [blitEncoder endEncoding];
    [cmdBuffer commit];
    [cmdBuffer waitUntilCompleted];
}

#pragma mark Private Methods

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::ensureAssociated() const
{
    if (!this->_dev)
        ALICEVISION_THROW_ERROR("Accessing a MTLDeviceMemory which has not been asscoiated with an MTLDevice!");
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::ensureAllocated() const
{
    if (!this->_buffer)
        ALICEVISION_THROW_ERROR("Accessing a MTLDeviceMemory which has not been allocated!");
}

#pragma mark Public Interface

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
MTLDeviceMemory<T, Dim, MemType>::MTLDeviceMemory()
{
    // Null pointer == not associated
    this->_dev = nullptr;
    // Null pointer == not allocated
    this->_buffer = nullptr;
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::associateWithMTLDevice(id<MTLDevice> dev)
{ this->_dev = dev; }

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::allocate1D(const MTLResourceSize<1>& extent)
    requires(Dim == 1)
{
    // Ensure device is asscoiated
    this->ensureAssociated();

    id<MTLDevice> dev = this->_dev;
    const size_t requestedSizeInBytes = this->_typeSize * extent.width();

    this->_totalElements = extent.width();
    this->_totalAllocatedSize = requestedSizeInBytes;
    this->_elementsPerDim[0] = extent.width();
    this->_allocatedSizePerDim[0] = extent.width() * sizeof(T);

    // Not host visible
    if constexpr (MemType == MemoryType::DeviceOnly)
    {
        this->_buffer = [dev newBufferWithLength:requestedSizeInBytes options:MTLResourceStorageModePrivate];
        this->_syncRequired = false;
        return;
    }

    bool shared, managed;
    checkSharedMemoryType(this->_dev, shared, managed);

    MTLResourceOptions memOptions = shared ? MTLResourceStorageModeShared : MTLResourceStorageModeManaged;

    this->_buffer = [dev newBufferWithLength:requestedSizeInBytes options:memOptions];

    this->_syncRequired = managed ? true : false;
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::allocate2D(const MTLResourceSize<2>& extent)
    requires(Dim == 2)
{
    // Ensure device is asscoiated
    this->ensureAssociated();

    id<MTLDevice> dev = this->_dev;
    const size_t requestedSizeInBytes = this->_typeSize * (extent.width() * extent.height());

    this->_totalElements = extent.width() * extent.height();
    this->_totalAllocatedSize = requestedSizeInBytes;
    this->_elementsPerDim[0] = extent.width();
    this->_allocatedSizePerDim[0] = extent.width() * sizeof(T);
    this->_elementsPerDim[1] = extent.height();
    this->_allocatedSizePerDim[1] = extent.height() * sizeof(T);

    // Not host visible
    if constexpr (MemType == MemoryType::DeviceOnly)
    {
        this->_buffer = [dev newBufferWithLength:requestedSizeInBytes options:MTLResourceStorageModePrivate];
        this->_syncRequired = false;
        return;
    }

    bool shared, managed;
    checkSharedMemoryType(this->_dev, shared, managed);

    MTLResourceOptions memOptions = shared ? MTLResourceStorageModeShared : MTLResourceStorageModeManaged;

    this->_buffer = [dev newBufferWithLength:requestedSizeInBytes options:memOptions];

    this->_syncRequired = managed ? true : false;
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::allocate3D(const MTLResourceSize<3>& extent)
    requires(Dim == 3)
{
    // Ensure device is asscoiated
    this->ensureAssociated();

    id<MTLDevice> dev = this->_dev;
    const size_t requestedSizeInBytes = this->_typeSize * (extent.width() * extent.height() * extent.depth());

    this->_totalElements = extent.width() * extent.height() * extent.depth();
    this->_totalAllocatedSize = requestedSizeInBytes;
    this->_elementsPerDim[0] = extent.width();
    this->_allocatedSizePerDim[0] = extent.width() * sizeof(T);
    this->_elementsPerDim[1] = extent.height();
    this->_allocatedSizePerDim[1] = extent.height() * sizeof(T);
    this->_elementsPerDim[2] = extent.depth();
    this->_allocatedSizePerDim[2] = extent.depth() * sizeof(T);

    // Not host visible
    if constexpr (MemType == MemoryType::DeviceOnly)
    {
        this->_buffer = [dev newBufferWithLength:requestedSizeInBytes options:MTLResourceStorageModePrivate];
        this->_syncRequired = false;
        return;
    }

    bool shared, managed;
    checkSharedMemoryType(this->_dev, shared, managed);

    MTLResourceOptions memOptions = shared ? MTLResourceStorageModeShared : MTLResourceStorageModeManaged;

    this->_buffer = [dev newBufferWithLength:requestedSizeInBytes options:memOptions];

    this->_syncRequired = managed ? true : false;
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::readOnHost(std::function<void(const std::mdspan<const T, std::dextents<size_t, Dim>> roData)> accessorFn) const
    requires(MemType == MemoryType::HostVisible)
{
    // Synchronize GPU changes to be visible to the host
    if (this->_syncRequired)
        synchronizeDeviceMemory(this->_dev, this->_buffer);

    void* rawBufferContent = [this->_buffer contents];

    if constexpr (Dim == 1)
    {
        accessorFn(std::mdspan<const T, std::dextents<size_t, Dim>>(static_cast<const T*>(rawBufferContent), this->_elementsPerDim[0]));
    }
    else if constexpr (Dim == 2)
    {
        accessorFn(std::mdspan<const T, std::dextents<size_t, Dim>>(
          static_cast<const T*>(rawBufferContent), this->_elementsPerDim[0], this->_elementsPerDim[1]));
    }
    else if constexpr (Dim == 3)
    {
        accessorFn(std::mdspan<const T, std::dextents<size_t, Dim>>(
          static_cast<const T*>(rawBufferContent), this->_elementsPerDim[0], this->_elementsPerDim[1], this->_elementsPerDim[2]));
    }
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
void MTLDeviceMemory<T, Dim, MemType>::writeFromHost(std::function<void(const std::mdspan<T, std::dextents<size_t, Dim>> rwData)> accessorFn)
    requires(MemType == MemoryType::HostVisible)
{
    // Because this could potentially also be a read, perform a synchronization
    // here as well
    // Synchronize GPU changes to be visible to the host
    if (this->_syncRequired)
        synchronizeDeviceMemory(this->_dev, this->_buffer);

    void* rawBufferContent = [this->_buffer contents];

    if constexpr (Dim == 1)
    {
        accessorFn(std::mdspan<T, std::dextents<size_t, Dim>>(static_cast<T*>(rawBufferContent), this->_elementsPerDim[0]));
    }
    else if constexpr (Dim == 2)
    {
        accessorFn(std::mdspan<T, std::dextents<size_t, Dim>>(static_cast<T*>(rawBufferContent), this->_elementsPerDim[0], this->_elementsPerDim[1]));
    }
    else if constexpr (Dim == 3)
    {
        accessorFn(std::mdspan<T, std::dextents<size_t, Dim>>(
          static_cast<T*>(rawBufferContent), this->_elementsPerDim[0], this->_elementsPerDim[1], this->_elementsPerDim[2]));
    }

    // Synchronize explicitly if required
    if (this->_syncRequired)
        [this->_buffer didModifyRange:NSMakeRange(0, this->_totalAllocatedSize)];
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
template<MemoryType MemTypeRHS>
void MTLDeviceMemory<T, Dim, MemType>::copyFromOtherBuffer(const MTLDeviceMemory<T, Dim, MemTypeRHS>& rhs)
{
    // Both buffers must be allocated and associated
    this->ensureAssociated();
    this->ensureAllocated();
    rhs.ensureAssociated();
    rhs.ensureAllocated();

    // Buffers must have the same associated device
    if ([this->_dev registryID] != [rhs._dev registryID])
        ALICEVISION_THROW_ERROR("Unable to copy from MTLDeviceMemory associated with device "
                                << [rhs._dev registryID] << " into MTLDeviceMemory associated with device " << [this->_dev registryID] << "!");

    // Buffers must be same size
    if ([this->_buffer allocatedSize] != [rhs._buffer allocatedSize])
        ALICEVISION_THROW_ERROR("Unable to copy from MTLDeviceMemory with size " << [rhs._buffer allocatedSize] << " into MTLDeviceMemory with size "
                                                                                 << [this->_buffer allocatedSize] << "!");

    // Copy using a Blit Command Encoder
    id<MTLCommandQueue> cmdQueue = DeviceManager::instance().getCMDManager(this->_dev).getCMDQueue();
    id<MTLCommandBuffer> cmdBuffer = [cmdQueue commandBuffer];
    id<MTLBlitCommandEncoder> blitEncoder = [cmdBuffer blitCommandEncoder];
    [blitEncoder copyFromBuffer:rhs._buffer sourceOffset:0 toBuffer:this->_buffer destinationOffset:0 size:this->_totalAllocatedSize];
    [blitEncoder endEncoding];
    [cmdBuffer commit];
    [cmdBuffer waitUntilCompleted];
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
size_t MTLDeviceMemory<T, Dim, MemType>::getAllocationSize() const
{
    this->ensureAssociated();

    if (!this->_buffer)
        return 0;

    return [this->_buffer allocatedSize];
}

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
id<MTLDevice> MTLDeviceMemory<T, Dim, MemType>::getAssociatedDevice() const
{ return this->_dev; }

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
id<MTLBuffer> MTLDeviceMemory<T, Dim, MemType>::getMTLBuffer()
{ return this->_buffer; }

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
MTLResourceSize<1> MTLDeviceMemory<T, Dim, MemType>::getSize() const
    requires(Dim == 1)
{ return MTLResourceSize<1>(this->_elementsPerDim[0]); }

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
MTLResourceSize<2> MTLDeviceMemory<T, Dim, MemType>::getSize() const
    requires(Dim == 2)
{ return MTLResourceSize<2>(this->_elementsPerDim[0], this->_elementsPerDim[1]); }

template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
MTLResourceSize<3> MTLDeviceMemory<T, Dim, MemType>::getSize() const
    requires(Dim == 3)
{ return MTLResourceSize<3>(this->_elementsPerDim[0], this->_elementsPerDim[1], this->_elementsPerDim[2]); }

}  // namespace aliceVision::depthMap::mtl
