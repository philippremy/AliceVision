// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains all shared type definitions (MTLRGBA, TSim, etc...)
 */

#pragma once

#include <aliceVision/depthMap_mtl/Config.h>
#include <aliceVision/depthMap_mtl/Namespace.hpp>

#if defined(__METAL__)
    #include <metal_stdlib>
using namespace metal;
#elif defined(__cplusplus) && !defined(__METAL__)
    #include <cstddef>
    #include <cstdint>
    #include <simd/vector_types.h>
#endif

ALICEVISION_DEPTHMAP_MTL_NS_START

/* clang-format off */

// Create a half type if we are using anything with a 16-bit floating value
//
// On C++, we require a compiler that supports the _Float16 type, which is
// checked by requiring FLT16_MIN and FLT16_MAX to be defined (with
// __STDC_WANT_IEC_60559_TYPES_EXT__).
//
// On Metal, the half type is built-in.

/* half definition */
#if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF) || defined(ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_HALF)
    #if defined(__METAL__)
        using _half = half;
    #elif defined(__cplusplus) && !defined(__METAL__)
        /* FIXME: Once the project supports C++23 and the compiler has the
         *       stdfloat header, switch to `float16_t`. For now we rely on
         *       compiler specific extensions.
        */
        #include <float.h>  // IWYU pragma: keep
        #if (defined(FLT16_MIN) && defined(FLT16_MAX))
            using _half = _Float16;
        #else
            #error Compiling with ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF or ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_HALF currently requires a compiler with support for the _Float16 extension
        #endif
    #else
        #error UNREACHABLE: Either __METAL__ or __cplusplus must be defined!
    #endif
#endif

/* MTLRGBA Base Type Definition */

#if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_UCHAR)
    using MTLRGBABaseType = unsigned char;
#elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF)
    using MTLRGBABaseType = _half;
#elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_FLOAT)
    using MTLRGBABaseType = float;
#else
    #error No DepthMap granularity chosen: Define either ALICEVISION_DEPTHMAP_TEXTURE_USE_UCHAR, ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF or ALICEVISION_DEPTHMAP_TEXTURE_USE_FLOAT in Config.hpp
#endif

/* TSim/TSimAcc Type Definition */

#if defined(ALICEVISION_DEPTHMAP_TSIM_USE_UCHAR)
    using TSim = unsigned char;
    using TSimAcc = uint32_t;   // Make 32-bit size explicit
#elif defined(ALICEVISION_DEPTHMAP_TSIM_USE_FLOAT)
    using TSim = float;
    using TSimAcc = float;
#else
    #error No TSim/TSimAcc granularity chosen: Define either ALICEVISION_DEPTHMAP_TSIM_USE_UCHAR or ALICEVISION_DEPTHMAP_TSIM_USE_FLOAT in Config.hpp
#endif

/* TSimRefine Type Definition */

#if defined(ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_HALF)
    using TSimRefine = _half;
#elif defined(ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_FLOAT)
    using TSimRefine = float;
#else
    #error No TSimRefine granularity chosen: Define either ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_HALF or ALICEVISION_DEPTHMAP_TSIM_REFINE_USE_FLOAT in Config.hpp
#endif

/* Additional definitions for C++, which are only available in Metal
 * These have specific alignment requirements, so we use the simd
 * types provided by Apple.
 */
#if defined(__cplusplus) && !defined(__METAL__)

    /**
     * @brief A two component 32-bit floating point type vector type
     */
    using float2 = simd_float2;

    /**
     * @brief A three component 32-bit floating point type vector type
     */
    using float3 = simd_float3;

    /**
     * @brief A three component 32-bit integer type vector type
     */
    using int3 = simd_int3;

#endif

/* clang-format on */

/**
 * @brief A type representing an RGBA pixel
 */
#if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_UCHAR)
using MTLRGBA = simd_uchar4;
#elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF)
using MTLRGBA = simd_half4;
#elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_FLOAT)
using MTLRGBA = simd_float4;
#endif

/* C++ only */

#if defined(__cplusplus) && !defined(__METAL__)

/**
 * @brief An enum class specifiying different kinds of device memory
 */
enum class MemoryType
{
    DeviceOnly,
    HostVisible,
};

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
struct MTLResourceSize
{
  public:
    MTLResourceSize() = delete;
    MTLResourceSize(size_t width)
        requires(Dim == 1);
    MTLResourceSize(size_t width, size_t height)
        requires(Dim == 2);
    MTLResourceSize(size_t width, size_t height, size_t depth)
        requires(Dim == 3);

    const size_t& width() const
        requires(Dim >= 1);
    const size_t& height() const
        requires(Dim >= 2);
    const size_t& depth() const
        requires(Dim >= 3);

    size_t& width()
        requires(Dim >= 1);
    size_t& height()
        requires(Dim >= 2);
    size_t& depth()
        requires(Dim >= 3);

  private:
    size_t _dimExtents[Dim];
};

#endif

ALICEVISION_DEPTHMAP_MTL_NS_END

#ifndef MTL_RESOURCE_SIZE_INL
    #define MTL_RESOURCE_SIZE_INL
    #include <aliceVision/depthMap_mtl/inline/MTLResourceSize.inl>
#endif
