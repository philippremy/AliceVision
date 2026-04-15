// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#import <aliceVision/depthMap_mtl/private/DeviceMipmapImage.hpp>

#include <aliceVision/depthMap_mtl/Config.h>
#include <aliceVision/depthMap_mtl/Types.hpp>

#import <aliceVision/depthMap_mtl/private/DeviceManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceColorConversion.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceCommandManager.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceGaussianFilter.hpp>
#import <aliceVision/depthMap_mtl/private/DeviceMipmappedTexture.hpp>

#include <aliceVision/mvsUtils/ImagesCache.hpp>
#include <aliceVision/numeric/numeric.hpp>
#include <aliceVision/system/Logger.hpp>

#import <Metal/MTLBlitCommandEncoder.h>
#import <Metal/MTLBuffer.h>
#import <Metal/MTLCommandBuffer.h>
#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLPixelFormat.h>
#import <Metal/MTLTexture.h>
#import <Metal/MTLTypes.h>

/* Definitions of forward declared types must be last */

#import <aliceVision/depthMap_mtl/private/MTLDeviceImpl.hpp>
#import <aliceVision/depthMap_mtl/private/MTLDeviceMemoryImpl.hpp>

#include <fstream>

namespace aliceVision::depthMap::mtl {

#pragma mark Private Methods

void DeviceMipmapImage::ensureAssociated() const
{
    if (!this->_dev)
        ALICEVISION_THROW_ERROR("Accessing a MTLDeviceMemory which has not been asscoiated with an MTLDevice!");
}

void DeviceMipmapImage::ensureAllocated() const
{
    if (!this->_texture)
        ALICEVISION_THROW_ERROR("Accessing a MTLDeviceMemory which has not been allocated!");
}

#pragma mark Public Interface

void DeviceMipmapImage::associateWithMTLDevice(id<MTLDevice> dev) { this->_dev = dev; }

void DeviceMipmapImage::allocate(MTLResourceSize<2> extent, unsigned int minDownscale, unsigned int maxDownscale)
{
    this->ensureAssociated();

    // update private members
    _minDownscale = minDownscale;
    _maxDownscale = maxDownscale;
    _width = extent.width();
    _height = extent.height();
    _levels = log2(maxDownscale / minDownscale) + 1;

    // Pixel Format differs on config
    /* clang-format off */
    #if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_UCHAR)
        #if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_INTERPOLATION)
            MTLPixelFormat pixelFormat = MTLPixelFormatRGBA8Unorm;      // Normalized to 0.0 - 1.0 (float)
        #else
            MTLPixelFormat pixelFormat = MTLPixelFormatRGBA8Uint;       // Unnormalized to 0 - 255
        #endif
    #elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF)
        MTLPixelFormat pixelFormat = MTLPixelFormatRGBA16Float;
    #elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_FLOAT)
        MTLPixelFormat pixelFormat = MTLPixelFormatRGBA32Float;
    #endif
    /* clang-format on */

    // Create the MTLTextureDescriptor
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat
                                                                                    width:this->_width
                                                                                   height:this->_height
                                                                                mipmapped:NO];

    desc.mipmapLevelCount = this->_levels;
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsagePixelFormatView;

    this->_texture = [this->_dev newTextureWithDescriptor:desc];
    if (!this->_texture)
        ALICEVISION_THROW_ERROR("Failed to allocate MTLTexture for a DeviceMipmapImage with dimensions: (" << this->_width << ", " << this->_height
                                                                                                           << ")!");
}

void DeviceMipmapImage::fill(mvsUtils::ImagesCache<image::Image<image::RGBAfColor>>::ImgSharedPtr img)
{
    this->ensureAssociated();
    this->ensureAllocated();

    std::vector<MTLRGBA> imgData = std::vector<MTLRGBA>(img->width() * img->height());

    for (int y = 0; y < img->height(); ++y)
    {
        for (int x = 0; x < img->width(); ++x)
        {
            const image::RGBAfColor& floatRGBA = (*img)(y, x);
            MTLRGBA& mtlRGBA = imgData[y * img->width() + x];
#ifdef ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF
            // explicit float to half conversion
            mtlRGBA.x = static_cast<_Float16>(floatRGBA.r() * 255.0f);
            mtlRGBA.y = static_cast<_Float16>(floatRGBA.g() * 255.0f);
            mtlRGBA.z = static_cast<_Float16>(floatRGBA.b() * 255.0f);
            mtlRGBA.w = static_cast<_Float16>(floatRGBA.a() * 255.0f);
#else
            mtlRGBA.x = floatRGBA.r() * 255.0f;
            mtlRGBA.y = floatRGBA.g() * 255.0f;
            mtlRGBA.z = floatRGBA.b() * 255.0f;
            mtlRGBA.w = floatRGBA.a() * 255.0f;
#endif
        }
    }

    [this->_texture replaceRegion:MTLRegionMake2D(0, 0, img->width(), img->height())
                      mipmapLevel:0
                        withBytes:imgData.data()
                      bytesPerRow:(img->width() * sizeof(MTLRGBA))];

    // downscale device-sided full-size input image buffer to min downscale
    if (this->_minDownscale > 1)
    {
        const size_t downscaledWidth = size_t(divideRoundUp(int(_width), int(this->_minDownscale)));
        const size_t downscaledHeight = size_t(divideRoundUp(int(_height), int(this->_minDownscale)));

        // Pixel Format differs on config
        /* clang-format off */
        #if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_UCHAR)
            #if defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_INTERPOLATION)
                MTLPixelFormat pixelFormat = MTLPixelFormatRGBA8Unorm;      // Normalized to 0.0 - 1.0 (float)
            #else
                MTLPixelFormat pixelFormat = MTLPixelFormatRGBA8Uint;       // Unnormalized to 0 - 255
            #endif
        #elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_HALF)
            MTLPixelFormat pixelFormat = MTLPixelFormatRGBA16Float;
        #elif defined(ALICEVISION_DEPTHMAP_TEXTURE_USE_FLOAT)
            MTLPixelFormat pixelFormat = MTLPixelFormatRGBA32Float;
        #endif
        /* clang-format on */

        // Create the MTLTextureDescriptor
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:[this->_texture pixelFormat]
                                                                                        width:downscaledWidth
                                                                                       height:downscaledHeight
                                                                                    mipmapped:NO];

        desc.mipmapLevelCount = this->_levels;
        desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;

        id<MTLTexture> downscaledTexture = [this->_dev newTextureWithDescriptor:desc];
        if (!downscaledTexture)
            ALICEVISION_THROW_ERROR("Failed to allocate MTLTexture for a downscaled DeviceMipmapImage with dimensions: ("
                                    << downscaledWidth << ", " << downscaledHeight << ")!");

        // This must be awaited, because we depend on the texture being
        // downscaled before continuing.
        MTL_downscaleWithGaussianBlur(downscaledTexture, this->_texture, this->_minDownscale, this->_minDownscale /* Gaussian Radius */, this->_dev);

        // Swap to downscaled texture
        this->_texture = downscaledTexture;
    }

    // Must be awaited
    MTL_rgb2lab(this->_texture, this->_dev);

    // Must be awaited
    MTL_createMipmappedArray(this->_texture, this->_levels, this->_dev);
}

float DeviceMipmapImage::getLevel(unsigned int downscale) const
{
    // check given downscale
    if (downscale < _minDownscale || downscale > _maxDownscale)
        ALICEVISION_THROW_ERROR("Cannot get device mipmap image level (downscale: " << downscale << ")!");

    return log2(float(downscale) / float(_minDownscale));
}

MTLResourceSize<2> DeviceMipmapImage::getDimensions(unsigned int downscale) const
{
    // check given downscale
    if (downscale < _minDownscale || downscale > _maxDownscale)
        ALICEVISION_THROW_ERROR("Cannot get device mipmap image level dimensions (downscale: " << downscale << ")!");

    return MTLResourceSize<2>(divideRoundUp(int(_width), int(downscale)), divideRoundUp(int(_height), int(downscale)));
}

}  // namespace aliceVision::depthMap::mtl
