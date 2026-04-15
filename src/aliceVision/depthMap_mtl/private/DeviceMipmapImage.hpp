// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains a class handling mipmapped images using MTLTextures
 */

#pragma once

#include <aliceVision/depthMap_mtl/ForwardDecls.hpp>
#include <aliceVision/depthMap_mtl/Types.hpp>

#include <aliceVision/mvsUtils/ImagesCache.hpp>

#include <memory>

#import <Metal/MTLDevice.h>
#import <Metal/MTLTexture.h>

namespace aliceVision::depthMap::mtl {

class DeviceMipmapImage final
{
  public:
    DeviceMipmapImage() = default;

    /* No copy/move constructors */
    /* Or yes? */
    DeviceMipmapImage(DeviceMipmapImage const&) = delete;
    DeviceMipmapImage(DeviceMipmapImage const&&) = delete;
    DeviceMipmapImage operator=(DeviceMipmapImage const&) = delete;
    DeviceMipmapImage operator=(DeviceMipmapImage const&&) = delete;

    /**
     * @brief Associates the instance with a specific MTLDevice
     *
     * @note This function *must* be called *once* before the any first other
     *       method call! If called a second time, this function is a no-op.
     */
    void associateWithMTLDevice(id<MTLDevice> dev);

    /**
     * @brief Allocate a new texture with the given extent, minimum downscale
     *        and maximum downscale.
     */
    void allocate(MTLResourceSize<2> extent, unsigned int minDownscale, unsigned int maxDownscale);

    /**
     * @brief Fills the complete mip pyramid with image data provided by in_img_hmh
     */
    void fill(mvsUtils::ImagesCache<image::Image<image::RGBAfColor>>::ImgSharedPtr img);

    /**
     * @brief Get the corresponding mipmap image level of the given downscale
     * @note throw if the given downscale is not contained in the mipmap image
     * @return corresponding mipmap image level
     */
    float getLevel(unsigned int downscale) const;

    /**
     * @brief Get the corresponding mipmap image level dimensions (width,
     *        height) of the given downscale
     *
     * @throws If the given downscale is not contained in the mipmap image
     *
     * @return Corresponding mipmap image downscale level dimensions
     */
    MTLResourceSize<2> getDimensions(unsigned int downscale) const;

    /**
     * @brief Get device mipmap image minimum (first) downscale level
     *
     * @return First level downscale factor (must be power of two)
     */
    inline unsigned int getMinDownscale() const { return _minDownscale; }

    /**
     * @brief Get device mipmap image maximum (last) downscale level
     *
     * @return Last level downscale factor (must be power of two)
     */
    inline unsigned int getMaxDownscale() const { return _maxDownscale; }

    /**
     * @brief Get the underlying MTLTexture object
     *
     * @return A strong id<MTLTexture>
     */
    inline id<MTLTexture> getMTLTexture() const { return _texture; }

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

    __strong id<MTLDevice> _dev;  //< The associated device

    __strong id<MTLTexture> _texture;  //< The underlying MTLTexture

    unsigned int _minDownscale = 0;  //< the min downscale factor (must be power of two), first downscale level
    unsigned int _maxDownscale = 0;  //< the max downscale factor (must be power of two), last downscale level
    unsigned int _levels = 0;        //< the number of downscale levels in the mipmapped array
    size_t _width = 0;               //< original image buffer width (no downscale)
    size_t _height = 0;              //< original image buffer height (no downscale)
};

}  // namespace aliceVision::depthMap::mtl
