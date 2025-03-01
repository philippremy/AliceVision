// This file is part of the AliceVision project.
// Copyright (c) 2016 AliceVision contributors.
// Copyright (c) 2012 openMVG contributors.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/.

#pragma once

#include "aliceVision/image/Image.hpp"

namespace aliceVision {
namespace image {

/// Put the pixel in the image to the given color only if the point (xc,yc)
///  is inside the image.
/// /!\ Be careful at the order (Y,X).
template<typename Image, typename Color>
inline void safePutPixel(int yc, int xc, const Color& col, Image* pim)
{
    if (pim)
    {
        if (pim->contains(yc, xc))
            (*pim)(yc, xc) = col;
    }
}

// Bresenham approach to draw ellipse.
// http://raphaello.univ-fcomte.fr/ig/algorithme/ExemplesGLUt/BresenhamEllipse.htm
// Add the rotation of the ellipse.
// As the algo. use symmetry we must use 4 rotations.
template<typename Image, typename Color>
void drawEllipse(int xc, int yc, int radiusA, int radiusB, const Color& col, Image* pim, double angle = 0.0)
{
    int a = radiusA, b = radiusB;

    // Counter Clockwise rotation matrix.
    double matXY[4] = {cos(angle), sin(angle), -sin(angle), cos(angle)};
    int x, y;
    double d1, d2;
    x = 0;
    y = b;
    d1 = b * b - a * a * b + a * a / 4;

    int rotX = ceil(matXY[0] * x + matXY[1] * y);
    int rotY = ceil(matXY[2] * x + matXY[3] * y);
    safePutPixel(yc + rotY, xc + rotX, col, pim);
    rotX = matXY[0] * x - matXY[1] * y;
    rotY = matXY[2] * x - matXY[3] * y;
    safePutPixel(yc + rotY, xc + rotX, col, pim);
    rotX = -matXY[0] * x - matXY[1] * y;
    rotY = -matXY[2] * x - matXY[3] * y;
    safePutPixel(yc + rotY, xc + rotX, col, pim);
    rotX = -matXY[0] * x + matXY[1] * y;
    rotY = -matXY[2] * x + matXY[3] * y;
    safePutPixel(yc + rotY, xc + rotX, col, pim);

    while (a * a * (y - .5) > b * b * (x + 1))
    {
        if (d1 < 0)
        {
            d1 += b * b * (2 * x + 3);
            ++x;
        }
        else
        {
            d1 += b * b * (2 * x + 3) + a * a * (-2 * y + 2);
            ++x;
            --y;
        }
        rotX = matXY[0] * x + matXY[1] * y;
        rotY = matXY[2] * x + matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
        rotX = matXY[0] * x - matXY[1] * y;
        rotY = matXY[2] * x - matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
        rotX = -matXY[0] * x - matXY[1] * y;
        rotY = -matXY[2] * x - matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
        rotX = -matXY[0] * x + matXY[1] * y;
        rotY = -matXY[2] * x + matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
    }
    d2 = b * b * (x + .5) * (x + .5) + a * a * (y - 1) * (y - 1) - a * a * b * b;
    while (y > 0)
    {
        if (d2 < 0)
        {
            d2 += b * b * (2 * x + 2) + a * a * (-2 * y + 3);
            --y;
            ++x;
        }
        else
        {
            d2 += a * a * (-2 * y + 3);
            --y;
        }
        rotX = matXY[0] * x + matXY[1] * y;
        rotY = matXY[2] * x + matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
        rotX = matXY[0] * x - matXY[1] * y;
        rotY = matXY[2] * x - matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
        rotX = -matXY[0] * x - matXY[1] * y;
        rotY = -matXY[2] * x - matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
        rotX = -matXY[0] * x + matXY[1] * y;
        rotY = -matXY[2] * x + matXY[3] * y;
        safePutPixel(yc + rotY, xc + rotX, col, pim);
    }
}

// Bresenham approach do not allow to draw concentric circle without holes.
// So it's better the use the Andres method.
// http://fr.wikipedia.org/wiki/Algorithme_de_tracé_de_cercle_d'Andres.
template<typename Image, typename Color>
void drawCircle(int x, int y, int radius, const Color& col, Image* pim)
{
    Image& im = *pim;
    if (im.contains(y + radius, x + radius) || im.contains(y + radius, x - radius) || im.contains(y - radius, x + radius) ||
        im.contains(y - radius, x - radius))
    {
        int x1 = 0;
        int y1 = radius;
        int d = radius - 1;
        while (y1 >= x1)
        {
            // Draw the point for each octant.
            safePutPixel(y1 + y, x1 + x, col, pim);
            safePutPixel(x1 + y, y1 + x, col, pim);
            safePutPixel(y1 + y, -x1 + x, col, pim);
            safePutPixel(x1 + y, -y1 + x, col, pim);
            safePutPixel(-y1 + y, x1 + x, col, pim);
            safePutPixel(-x1 + y, y1 + x, col, pim);
            safePutPixel(-y1 + y, -x1 + x, col, pim);
            safePutPixel(-x1 + y, -y1 + x, col, pim);
            if (d >= 2 * x1)
            {
                d = d - 2 * x1 - 1;
                x1 += 1;
            }
            else
            {
                if (d <= 2 * (radius - y1))
                {
                    d = d + 2 * y1 - 1;
                    y1 -= 1;
                }
                else
                {
                    d = d + 2 * (y1 - x1 - 1);
                    y1 -= 1;
                    x1 += 1;
                }
            }
        }
    }
}

// Bresenham algorithm
template<typename Image, typename Color>
void drawLine(int xa, int ya, int xb, int yb, const Color& col, Image* pim)
{
    Image& im = *pim;

    // If one point is outside the image
    // Replace the outside point by the intersection of the line and
    // the limit (either x=width or y=height).
    if (!im.contains(ya, xa) || !im.contains(yb, xb))
    {
        int width = pim->width(), height = pim->height();
        const bool xdir = xa < xb, ydir = ya < yb;
        float nx0 = float(xa), nx1 = float(xb), ny0 = float(ya), ny1 = float(yb), &xleft = xdir ? nx0 : nx1, &yleft = xdir ? ny0 : ny1,
              &xright = xdir ? nx1 : nx0, &yright = xdir ? ny1 : ny0, &xup = ydir ? nx0 : nx1, &yup = ydir ? ny0 : ny1, &xdown = ydir ? nx1 : nx0,
              &ydown = ydir ? ny1 : ny0;

        if (xright < 0 || xleft >= width)
            return;
        if (xleft < 0)
        {
            yleft -= xleft * (yright - yleft) / (xright - xleft);
            xleft = 0;
        }
        if (xright >= width)
        {
            yright -= (xright - width) * (yright - yleft) / (xright - xleft);
            xright = float(width) - 1;
        }
        if (ydown < 0 || yup >= height)
            return;
        if (yup < 0)
        {
            xup -= yup * (xdown - xup) / (ydown - yup);
            yup = 0;
        }
        if (ydown >= height)
        {
            xdown -= (ydown - height) * (xdown - xup) / (ydown - yup);
            ydown = float(height) - 1;
        }

        xa = (int)xleft;
        xb = (int)xright;
        ya = (int)yleft;
        yb = (int)yright;
    }

    int xbas, xhaut, ybas, yhaut;
    // Check the condition ybas < yhaut.
    if (ya <= yb)
    {
        xbas = xa;
        ybas = ya;
        xhaut = xb;
        yhaut = yb;
    }
    else
    {
        xbas = xb;
        ybas = yb;
        xhaut = xa;
        yhaut = ya;
    }
    // Initialize slope.
    int x, y, dx, dy, incrmX, incrmY, dp, N, S;
    dx = xhaut - xbas;
    dy = yhaut - ybas;
    if (dx > 0)
    {  // If xhaut > xbas we will increment X.
        incrmX = 1;
    }
    else
    {
        incrmX = -1;  // else we will decrement X.
        dx *= -1;
    }
    if (dy > 0)
    {  // Positive slope will increment X.
        incrmY = 1;
    }
    else
    {  // Negative slope.
        incrmY = -1;
    }
    if (dx >= dy)
    {
        dp = 2 * dy - dx;
        S = 2 * dy;
        N = 2 * (dy - dx);
        y = ybas;
        x = xbas;
        while (x != xhaut)
        {
            safePutPixel(y, x, col, pim);
            x += incrmX;
            if (dp <= 0)
            {  // Go in direction of the South Pixel.
                dp += S;
            }
            else
            {  // Go to the North.
                dp += N;
                y += incrmY;
            }
        }
    }
    else
    {
        dp = 2 * dx - dy;
        S = 2 * dx;
        N = 2 * (dx - dy);
        x = xbas;
        y = ybas;
        while (y < yhaut)
        {
            safePutPixel(y, x, col, pim);
            y += incrmY;
            if (dp <= 0)
            {  // Go in direction of the South Pixel.
                dp += S;
            }
            else
            {  // Go to the North.
                dp += N;
                x += incrmX;
            }
        }
    }
    safePutPixel(y, x, col, pim);
}

// Filled circle
// Exterior point computed with bresenham approach
// i.e: DrawCircle
template<typename Image, typename Color>
void filledCircle(int x, int y, int radius, const Color& col, Image* pim)
{
    Image& im = *pim;
    if (im.contains(y + radius, x + radius) || im.contains(y + radius, x - radius) || im.contains(y - radius, x + radius) ||
        im.contains(y - radius, x - radius))
    {
        int x1 = 0;
        int y1 = radius;
        int d = radius - 1;
        while (y1 >= x1)
        {
            drawLine(x1 + x, y1 + y, x1 + x, -y1 + y, col, pim);
            drawLine(y1 + x, x1 + y, y1 + x, -x1 + y, col, pim);
            drawLine(-x1 + x, y1 + y, -x1 + x, -y1 + y, col, pim);
            drawLine(-y1 + x, x1 + y, -y1 + x, -x1 + y, col, pim);
            if (d >= 2 * x1)
            {
                d = d - 2 * x1 - 1;
                x1 += 1;
            }
            else
            {
                if (d <= 2 * (radius - y1))
                {
                    d = d + 2 * y1 - 1;
                    y1 -= 1;
                }
                else
                {
                    d = d + 2 * (y1 - x1 - 1);
                    y1 -= 1;
                    x1 += 1;
                }
            }
        }
    }
}

// Draw a serie of circles along the line, the algorithm is slow but accurate
template<typename Image, typename Color>
void drawLineThickness(int xa, int ya, int xb, int yb, const Color& col, int thickness, Image* pim)
{
    Image& im = *pim;
    int halfThickness = (thickness + 1) / 2;

    // If one point is outside the image
    // Replace the outside point by the intersection of the line and
    // the limit (either x=width or y=height).
    if (!im.contains(ya, xa) || !im.contains(yb, xb))
    {
        int width = pim->width(), height = pim->height();
        const bool xdir = xa < xb, ydir = ya < yb;
        float nx0 = float(xa), nx1 = float(xb), ny0 = float(ya), ny1 = float(yb), &xleft = xdir ? nx0 : nx1, &yleft = xdir ? ny0 : ny1,
              &xright = xdir ? nx1 : nx0, &yright = xdir ? ny1 : ny0, &xup = ydir ? nx0 : nx1, &yup = ydir ? ny0 : ny1, &xdown = ydir ? nx1 : nx0,
              &ydown = ydir ? ny1 : ny0;

        if (xright < 0 || xleft >= width)
            return;
        if (xleft < 0)
        {
            yleft -= xleft * (yright - yleft) / (xright - xleft);
            xleft = 0;
        }
        if (xright >= width)
        {
            yright -= (xright - width) * (yright - yleft) / (xright - xleft);
            xright = float(width) - 1;
        }
        if (ydown < 0 || yup >= height)
            return;
        if (yup < 0)
        {
            xup -= yup * (xdown - xup) / (ydown - yup);
            yup = 0;
        }
        if (ydown >= height)
        {
            xdown -= (ydown - height) * (xdown - xup) / (ydown - yup);
            ydown = float(height) - 1;
        }

        xa = (int)xleft;
        xb = (int)xright;
        ya = (int)yleft;
        yb = (int)yright;
    }

    int xbas, xhaut, ybas, yhaut;
    // Check the condition ybas < yhaut.
    if (ya <= yb)
    {
        xbas = xa;
        ybas = ya;
        xhaut = xb;
        yhaut = yb;
    }
    else
    {
        xbas = xb;
        ybas = yb;
        xhaut = xa;
        yhaut = ya;
    }
    // Initialize slope.
    int x, y, dx, dy, incrmX, incrmY, dp, N, S;
    dx = xhaut - xbas;
    dy = yhaut - ybas;
    if (dx > 0)
    {  // If xhaut > xbas we will increment X.
        incrmX = 1;
    }
    else
    {
        incrmX = -1;  // else we will decrement X.
        dx *= -1;
    }
    if (dy > 0)
    {  // Positive slope will increment X.
        incrmY = 1;
    }
    else
    {  // Negative slope.
        incrmY = -1;
    }
    if (dx >= dy)
    {
        dp = 2 * dy - dx;
        S = 2 * dy;
        N = 2 * (dy - dx);
        y = ybas;
        x = xbas;
        while (x != xhaut)
        {
            drawCircle(x, y, halfThickness, col, pim);
            x += incrmX;
            if (dp <= 0)
            {  // Go in direction of the South Pixel.
                dp += S;
            }
            else
            {  // Go to the North.
                dp += N;
                y += incrmY;
            }
        }
    }
    else
    {
        dp = 2 * dx - dy;
        S = 2 * dx;
        N = 2 * (dx - dy);
        x = xbas;
        y = ybas;
        while (y < yhaut)
        {
            drawCircle(x, y, halfThickness, col, pim);
            y += incrmY;
            if (dp <= 0)
            {  // Go in direction of the South Pixel.
                dp += S;
            }
            else
            {  // Go to the North.
                dp += N;
                x += incrmX;
            }
        }
    }
    drawCircle(x, y, halfThickness, col, pim);
}

}  // namespace image
}  // namespace aliceVision
