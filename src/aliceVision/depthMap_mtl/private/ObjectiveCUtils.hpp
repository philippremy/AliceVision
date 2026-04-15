// This file is part of the AliceVision project.
// Copyright (c) 2026 AliceVision contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

/**
 * This file contains helper functions for bridging C++ and Objective-C(++)
 */

#include <sstream>

#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>

namespace aliceVision::depthMap::mtl {

/**
 * @brief Converts a NSURL* to a std::string
 */
inline std::string string_from_nsurl(NSURL* url)
{
    std::stringstream buffer;
    if (url)
        buffer << [[url absoluteString] UTF8String];
    return buffer.str();
}

/**
 * @brief Converts a std::string to a NSURL*
 */
inline NSURL* nsurl_from_string(const std::string& str) { return [NSURL fileURLWithPath:[NSString stringWithUTF8String:str.c_str()]]; }

/**
 * @brief Converts a NSString* to a std::string
 */
inline std::string string_from_nsstring(NSString* str)
{
    std::stringstream buffer;
    if (str)
        buffer << [str UTF8String];
    return buffer.str();
}

/**
 * @brief Converts a std::string to a NSString*
 */
inline NSString* nsstring_from_string(const std::string& str) { return [NSString stringWithUTF8String:str.c_str()]; }

/**
 * @brief Converts a const char* to a NSString*
 */
inline NSString* nsstring_from_const_char_ptr(const char* str) { return [NSString stringWithUTF8String:str]; }

}  // namespace aliceVision::depthMap::mtl
