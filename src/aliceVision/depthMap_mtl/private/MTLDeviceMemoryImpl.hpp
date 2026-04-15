// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains the implementation of the MTLDeviceMemory forward
 * declared type
 */

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>

#include <aliceVision/depthMap_mtl/Types.hpp>

#include <cstdint>
#include <functional>
#include <mdspan>

#import <Metal/MTLBuffer.h>
#import <Metal/MTLCommandBuffer.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief An opaque handle to device memory
 *
 * @tparam T The type of data stored on the device, must comply with the
 *         MTLBufferSafe concept
 * @tparam Dim The number of dimensions this device memory has
 * @tparam MemType The type of memory the buffer should use
 */
template<MTLBufferSafe T, uint8_t Dim, MemoryType MemType>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
struct MTLDeviceMemory
{
    /* Make DeviceMipmapImage a friend class, so it can access the underlying
     * MTLBuffer */
    friend class DeviceMipmapImage;

    /* Make Self a friend class, so it can access the underlying MTLBuffer */
    template<MTLBufferSafe, uint8_t DimInner, MemoryType>
        requires(DimInner == 1 || DimInner == 2 || DimInner == 3)
    friend class MTLDeviceMemory;

    /**
     * @brief Default constructor, which does not allocate any device memory
     *        yet and is not associated with any special device
     */
    explicit MTLDeviceMemory();

    /* No copy/move constructors */
    /* Or yes? */
    MTLDeviceMemory(MTLDeviceMemory const&) = delete;
    MTLDeviceMemory(MTLDeviceMemory const&&) = delete;
    MTLDeviceMemory operator=(MTLDeviceMemory const&) = delete;
    MTLDeviceMemory operator=(MTLDeviceMemory const&&) = delete;

    /**
     * @brief Associates the instance with a specific MTLDevice
     *
     * @note This function *must* be called *once* before the any first other
     *       method call! If called a second time, this function is a no-op.
     */
    void associateWithMTLDevice(id<MTLDevice> dev);

    /**
     * @brief Allocate a 1D buffer with the specified width
     */
    void allocate1D(const MTLResourceSize<1>& extent)
        requires(Dim == 1);

    /**
     * @brief Allocate a 2D buffer with the specified width and height
     */
    void allocate2D(const MTLResourceSize<2>& extent)
        requires(Dim == 2);

    /**
     * @brief Allocate a 3D buffer with the specified width and height and
     *        depth
     */
    void allocate3D(const MTLResourceSize<3>& extent)
        requires(Dim == 3);

    /**
     * @brief Allows accessing the buffers data as an read only array of POD
     *
     * @param[in] accessorFn A function callback which provides scoped access
     *                       to the underlying buffer data (read-only)
     *
     * @warning The passed pointer to the buffer is only valid for the lifetime
     *          of the passed callback. If it is required to further use data
     *          after the callback returns, perform an explicit copy!
     */
    void readOnHost(std::function<void(const std::mdspan<const T, std::dextents<size_t, Dim>> roData)> accessorFn) const
        requires(MemType == MemoryType::HostVisible);

    /**
     * @brief Allows accessing the buffers data as a writable array of POD
     *
     * @param[in] accessorFn A function callback which provides scoped access
     *                       to the underlying buffer data (read-write)
     *
     * @note If the underlying buffer requires some kind of synchronization,
     *       this operation will mark the entire buffer as dirty. This might
     *       cause an expensive device to device memory copy, so use this
     *       function sparsely and ideally on large chunks of data.
     *
     * @warning The passed pointer to the buffer is only valid for the lifetime
     *          of the passed callback. If it is required to further use data
     *          after the callback returns, perform an explicit copy!
     */
    void writeFromHost(std::function<void(const std::mdspan<T, std::dextents<size_t, Dim>> rwData)> accessorFn)
        requires(MemType == MemoryType::HostVisible);

    /**
     * @brief Copies the data from rhs into the underlying buffer
     *
     * @param[in] rhs The other device memory instance to copy out of
     *
     * @throws A runtime exception if the underlying buffers are of different
     *         size, the buffers belong to different devices or the copy
     *         operation itself fails
     *
     * @warning This method must only be invoked if the underlying has already
     *          been allocated using one of the allocate* functions above.
     */
    template<MemoryType MemTypeRHS>
    void copyFromOtherBuffer(const MTLDeviceMemory<T, Dim, MemTypeRHS>& rhs);

    /**
     * @brief Returns the allocated size in bytes of the underlying MTLBuffer
     *
     * @throws A runtime exception if this instance is not associated with a
     *         device
     *
     * @note This method returns 0 if the MTLBuffer has not yet been allocated
     */
    size_t getAllocationSize() const;

    /**
     * @brief Returns the resource extent in a MTLResourceSize wrapper
     *
     * This is the 1D implementation, only returning a 1D MTLResourceSize
     * (width).
     *
     * @throws A runtime exception if this instance has not been associated
     *         with a device or has not yet been allocated.
     */
    MTLResourceSize<1> getSize() const
        requires(Dim == 1);

    /**
     * @brief Returns the resource extent in a MTLResourceSize wrapper
     *
     * This is the 2D implementation, only returning a 2D MTLResourceSize
     * (width and height).
     *
     * @throws A runtime exception if this instance has not been associated
     *         with a device or has not yet been allocated.
     */
    MTLResourceSize<2> getSize() const
        requires(Dim == 2);

    /**
     * @brief Returns the resource extent in a MTLResourceSize wrapper
     *
     * This is the 3D implementation, only returning a 3D MTLResourceSize
     * (width, height and depth).
     *
     * @throws A runtime exception if this instance has not been associated
     *         with a MTLDevice or has not yet been allocated.
     */
    MTLResourceSize<3> getSize() const
        requires(Dim == 3);

    /**
     * @brief Returns the associated MTLDevice
     *
     * @throws A runtime exception if this instance has not been associated
     *         with an MTLDevice.
     */
    id<MTLDevice> getAssociatedDevice() const;

    /**
     * @brief Returns the underlying MTLBuffer for this allocation
     *
     * @throws A runtime exception if this instance has not been associated
     *         with a MTLDevice or has not yet been allocated.
     *
     * @returns An associdated and allocated MTLBuffer
     */
    id<MTLBuffer> getMTLBuffer();

  private:
    /**
     * @brief Ensures the instance has been associated with a device
     *
     * @throws A runtime exception if the instance has not been associated with
     *         an MTLDevice
     */
    void ensureAssociated() const;

    /**
     * @brief Ensures the instance has been allocated
     *
     * @throws A runtime exception if the instance has not been allocated
     */
    void ensureAllocated() const;

    const size_t _typeSize = sizeof(T);  //< The size of the underlying data type in bytes
    size_t _totalAllocatedSize;          //< The total allocated size in bytes (whole buffer)
    size_t _allocatedSizePerDim[Dim];    //< The allocated size in bytes per dimension
    size_t _totalElements;               //< The total number of elements stored
    size_t _elementsPerDim[Dim];         //< The number of elements stored per dimension

    bool _syncRequired;              //< Whether the buffer requires explicit synchronization
    __strong id<MTLBuffer> _buffer;  //< Strong (i.e., owning pointer) to the underlying MTLBuffer
    __strong id<MTLDevice> _dev;     //< String (i.e., owning pointer) to the associated MTLDevice
};

}  // namespace aliceVision::depthMap::mtl

/* clang-format off */
// Include the inline definitions
#ifndef MTL_DEVICE_MEMORY_IMPL_INL
#define MTL_DEVICE_MEMORY_IMPL_INL
    #import <aliceVision/depthMap_mtl/private/inline/MTLDeviceMemoryImpl.inl>
#endif
/* clang-format on */
