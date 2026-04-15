// This file is part of the extension to AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/* C++ only */

#if defined(__cplusplus) && !defined(__METAL__)

/* clang-format off */
#ifndef MTL_RESOURCE_SIZE_INL
    #error This file cannot be included directly, include Types.hpp instead
#endif

#include <cstddef>
#include <cstdint>

/* clang-format on */

namespace aliceVision::depthMap::mtl {

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
MTLResourceSize<Dim>::MTLResourceSize(const size_t width)
    requires(Dim == 1)
{ this->_dimExtents[0] = width; }

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
MTLResourceSize<Dim>::MTLResourceSize(const size_t width, const size_t height)
    requires(Dim == 2)
{
    this->_dimExtents[0] = width;
    this->_dimExtents[1] = height;
}

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
MTLResourceSize<Dim>::MTLResourceSize(const size_t width, const size_t height, const size_t depth)
    requires(Dim == 3)
{
    this->_dimExtents[0] = width;
    this->_dimExtents[1] = height;
    this->_dimExtents[2] = depth;
}

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
const size_t& MTLResourceSize<Dim>::width() const
    requires(Dim >= 1)
{ return this->_dimExtents[0]; }

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
const size_t& MTLResourceSize<Dim>::height() const
    requires(Dim >= 2)
{ return this->_dimExtents[1]; }

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
const size_t& MTLResourceSize<Dim>::depth() const
    requires(Dim >= 3)
{ return this->_dimExtents[2]; }

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
size_t& MTLResourceSize<Dim>::width()
    requires(Dim >= 1)
{ return this->_dimExtents[0]; }

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
size_t& MTLResourceSize<Dim>::height()
    requires(Dim >= 2)
{ return this->_dimExtents[1]; }

template<uint8_t Dim>
    requires(Dim == 1 || Dim == 2 || Dim == 3)
size_t& MTLResourceSize<Dim>::depth()
    requires(Dim >= 3)
{ return this->_dimExtents[2]; }

}  // namespace aliceVision::depthMap::mtl

#endif
