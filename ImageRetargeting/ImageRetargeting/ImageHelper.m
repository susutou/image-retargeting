//
//  ImageHelper.m
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/13/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import "ImageHelper.h"
#import "Matrix.h"

@implementation ImageHelper

// derived from http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics
+ (NSArray *)getRGBAsFromImage:(UIImage *)image atX:(int)xx andY:(int)yy count:(int)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (int)((bytesPerRow * yy) + xx * bytesPerPixel);
    for (int ii = 0 ; ii < count ; ++ii)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        
        UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [result addObject:acolor];
    }
    
    free(rawData);
    
    return result;
}


+ (UIImage *)modifyImage:(UIImage *)image
{
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    //CGContextRelease(context);
    
    [ImageHelper resizer:imageRef withData:rawData];

    imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    free(rawData);
    
    //[NSData dataWithBytesNoCopy:rawData length:width * height];
    
    return newImage;
}

+ (UIImage *)modifyImageSeamCarvingShrinkHorizonal:(UIImage*)image
{
    
    return image;
}


+ (void) resizer:(CGImageRef)imageRef withData:(unsigned char *)data
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    double *gradient = [ImageHelper getGradientMatrixForImage:imageRef withData:data];
    double *expandedGradient = [ImageHelper expandMapForImage:imageRef withGradient:gradient];
    
    for (int i = 0; i < width * height; i += 1) {
        data[i * 4] = expandedGradient[i];
        data[i * 4 + 1] = expandedGradient[i];
        data[i * 4 + 2] = expandedGradient[i];
    }
    // 0.2989, 0.5870, 0.1140
    
    free(gradient);
    free(expandedGradient);
}


+ (double *) getGradientMatrixForImage:(CGImageRef)imageRef withData:(unsigned char *)data
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    double *grayscaleData = calloc(height * width, sizeof(double));
    
    // convert the image to grayscale
    for (int i = 0; i < width * height; i += 1) {
        int r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2];
        double intensity = r * 0.2989 + g * 0.5870 + b * 0.1140;
        grayscaleData[i] = intensity;
    }
    
    double *xGradient = calloc(height * width, sizeof(double));
    double *yGradient = calloc(height * width, sizeof(double));
    double *gradient = calloc(height * width, sizeof(double));
    
    double A[3][3];
    
    for (int i = 1; i < width - 1; i++) {
        for (int j = 1; j < height - 1; j++) {
            A[0][0] = grayscaleData[(j - 1) * width + (i - 1)];
            A[0][1] = grayscaleData[(j) * width + (i - 1)];
            A[0][2] = grayscaleData[(j + 1) * width + (i - 1)];
            A[1][0] = grayscaleData[(j - 1) * width + (i)];
            A[1][1] = grayscaleData[(j) * width + (i)];
            A[1][2] = grayscaleData[(j + 1) * width + (i)];
            A[2][0] = grayscaleData[(j - 1) * width + (i + 1)];
            A[2][1] = grayscaleData[(j) * width + (i + 1)];
            A[2][2] = grayscaleData[(j + 1) * width + (i + 1)];
            
            NSUInteger k = j * width + i;
            
            // compute Sobel kernel gradient
            xGradient[k] = -1 * A[0][0] - 2 * A[1][0] - 1 * A[2][0] + 1 * A[0][2] + 2 * A[1][2] + 1 * A[2][2];
            yGradient[k] = -1 * A[0][0] - 2 * A[0][1] - 1 * A[0][2] + 1 * A[2][0] + 2 * A[2][1] + 1 * A[2][2];
            gradient[k] = sqrt(xGradient[k] * xGradient[k] + yGradient[k] * yGradient[k]);

        }
    }
    
    // normalizing gradient
    double maxGradient = 0;
    
    for (int i = 0; i < width * height; i++) {
        if (gradient[i] > maxGradient) {
            maxGradient = gradient[i];
        }
    }
    
    for (int i = 0; i < width * height; i++) {
        gradient[i] = gradient[i] / maxGradient * 250;
    }
    
    free(grayscaleData);
    free(xGradient);
    free(yGradient);
    
    return gradient;
}

+ (double *)expandMapForImage:(CGImageRef)imageRef withGradient:(double *)gradient
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    double *expandedGradient = calloc(height * width, sizeof(double));
    int d = 4;  // stroke width
    
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            NSUInteger k = j * width + i;
            for (int dx = -d; dx <= d; dx++) {
                for (int dy = -d; dy < d; dy++) {
                    double dist = sqrt(dx * dx + dy * dy);
                    if (dist <= d) {
                        int xn = i + dx;
                        int yn = j + dy;
                        if (0 <= xn && xn < width && 0 <= yn && yn < height) {
                            expandedGradient[k] = MAX(expandedGradient[k], (0.5 + 0.5 * (d * d - dist * dist) / (d * d)) * gradient[yn * width + xn]);
                        }
                    }
                }
            }
        }
    }
    
    return expandedGradient;
}

// TODO: add face-detection

@end
























