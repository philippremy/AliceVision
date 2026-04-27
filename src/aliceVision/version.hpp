// This file is part of the AliceVision project.
// Copyright (c) 2016 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include <aliceVision/numeric/numeric.hpp>

// Preprocessor to string conversion
#define ALICEVISION_TO_STRING_HELPER(x) #x
#define ALICEVISION_TO_STRING(x) ALICEVISION_TO_STRING_HELPER(x)

namespace aliceVision {

class Version
{
  public:
    Version()
      : _v(Vec3i::Zero())
    {}

    explicit Version(const Vec3i& v)
      : _v(v)
    {}

    Version(int major, int minor, int micro)
      : _v(major, minor, micro)
    {}

    Version& operator=(const Vec3i& other)
    {
        _v = other;
        return *this;
    }

    bool operator<(const Version& other) const
    {
        for (Vec3i::Index i = 0; i < 3; i++)
        {
            if (_v[i] < other._v[i])
            {
                return true;
            }

            if (_v[i] > other._v[i])
            {
                return false;
            }
        }

        return false;
    }
    bool operator>=(const Version& other) const
    {
        return !operator<(other);
    }

  private:
    Vec3i _v;
};

}  // namespace aliceVision
