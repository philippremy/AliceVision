// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains routines used for color conversion
 */

#pragma once

#include <aliceVision/depthMap_mtl/Namespace.hpp>

#include <metal_stdlib>
using namespace metal;

ALICEVISION_DEPTHMAP_MTL_NS_START

template<typename T>
class BufPtrDevice
{
  public:
    BufPtrDevice(device T* ptr, size_t pitch)
      : _ptr(ptr),
        _pitch(pitch)
    {}

    inline device T* ptr() { return _ptr; }
    inline device T* row(size_t y) { return _ptr + y * _pitch; }
    inline device T& at(size_t x, size_t y) { return _ptr[y * _pitch + x]; }

    inline device const T* ptr() const { return _ptr; }
    inline device const T* row(size_t y) const { return _ptr + y * _pitch; }
    inline device const T& at(size_t x, size_t y) const { return _ptr[y * _pitch + x]; }

  private:
    BufPtrDevice();
    BufPtrDevice(device const BufPtrDevice&);
    device BufPtrDevice& operator*=(device const BufPtrDevice&);

    device T* const _ptr;
    const size_t _pitch; // elements per row
};

template<typename T>
class BufPtrConstant
{
  public:
    BufPtrConstant(constant T* ptr, size_t pitch)
      : _ptr(ptr),
        _pitch(pitch)
    {}

    inline constant T* ptr() { return _ptr; }
    inline constant T* row(size_t y) { return _ptr + y * _pitch; }
    inline constant T& at(size_t x, size_t y) { return _ptr[y * _pitch + x]; }

    inline constant const T* ptr() const { return _ptr; }
    inline constant const T* row(size_t y) const { return _ptr + y * _pitch; }
    inline constant const T& at(size_t x, size_t y) const { return _ptr[y * _pitch + x]; }

  private:
    BufPtrConstant();
    BufPtrConstant(constant const BufPtrConstant&);
    constant BufPtrConstant& operator*=(constant const BufPtrConstant&);

    constant T* const _ptr;
    const size_t _pitch; // elements per row
};

template<typename T>
inline device T* get3DBufferAtDevice(device T* ptr,
                                     const size_t sliceStride,  // in elements
                                     const size_t rowStride,    // in elements
                                     const size_t x,
                                     const size_t y,
                                     const size_t z)
{
    return ptr + z * sliceStride + y * rowStride + x;
}

template<typename T>
inline constant T* get3DBufferAtConstant(constant T* ptr,
                                         const size_t sliceStride,  // in elements
                                         const size_t rowStride,    // in elements
                                         const size_t x,
                                         const size_t y,
                                         const size_t z)
{
    return ptr + z * sliceStride + y * rowStride + x;
}

ALICEVISION_DEPTHMAP_MTL_NS_END
