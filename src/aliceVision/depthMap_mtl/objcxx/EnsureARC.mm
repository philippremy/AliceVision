// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/* This file has the only purpose to ensure that ARC is used when compiling the
 * library
 */

#ifndef __clang__
    #error This library can only be compiled with LLVM/Apple Clang, because it requires Automatic Reference Counting (ARC).
#endif

#if __has_feature(objc_arc)
/* Everything ok */
#else
    #error This library must be compiled with Automatic Reference Counting (ARC), which can be activated with "-fobjc-arc".
#endif
