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

+ (UIImage *)modifyImageSeamCarvingShrinkHorizonal:(UIImage*)image atWidth:(int)cur_width shrinkBy: (int) reduced_width
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
    
    [ImageHelper resizerSeamCarvingShrinkHorizonal:imageRef withData:rawData atWidth:cur_width shrinkBy:reduced_width];
    
    imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    free(rawData);
    
    //[NSData dataWithBytesNoCopy:rawData length:width * height];
    
    return newImage;
}

+ (void) resizerSeamCarvingShrinkHorizonal:(CGImageRef)imageRef withData:(unsigned char *)data atWidth:(int)cur_width shrinkBy:(int) reduced_width
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    // prepare data for dynamic programming
    
    double *energy = calloc(width*height , sizeof(double));
    double *dp = calloc(width*height, sizeof(double));
    int *direction = calloc(width*height, sizeof(int));
    uint32_t *to_delete = calloc(height, sizeof(uint32_t));
    uint8_t r, g, b;
    

    // dynamic programming
    for (int x = 0; x < cur_width; x++){
        dp[0 * width + x] = 0.0;
    }
    
    while (reduced_width--) {
        for (int y = 0; y < height; y++) {
            for (int x= 0; x < cur_width; x++) {
                // calculate the intensity with parameters:
                // 0.2989, 0.5870, 0.1140
                r = data[4 * (y * width + x) + 0];
                g = data[4 * (y * width + x) + 1];
                b = data[4 * (y * width + x) + 2];
                energy[y * width + x] = 0.2989*r + 0.5870*g + 0.1140*b;
            }
        }
        
        for (int y = 1; y <height; y++) {
            for (int x = 0; x < cur_width; x++) {
                dp[y*width + x] = 999999.9;
                for (int x_delta = -1; x_delta <= 1; x_delta++) {
                    if (x+x_delta >=0 && x+x_delta<cur_width) {
                        double new_value = dp[(y-1)*width + x + x_delta] +
                                           fabs(energy[y*width + x] - energy[(y-1)*width + x + x_delta]);
                        if (new_value < dp[y*width + x]) {
                            dp[y*width + x] = new_value;
                            direction[y*width + x] = x_delta;
                        }
                    }
                }
            }
        }
        
        double bottom_min_energy = 999999.9;
        for (int x = 0; x < cur_width; x++) {
            if (dp[width * (height-1) + x] < bottom_min_energy) {
                to_delete[height-1] = x;
                bottom_min_energy = dp[width * (height-1) + x];
            }
        }
        for (int y = (int)height-2; y>=0; y--) {
            to_delete[y] = to_delete[y+1] + direction[(y+1)*width + to_delete[y+1]];
        }
        
        // modify image data
        for (int y = 0; y<height; y++) {
            for (int x = 0; x < cur_width-1; x++) {
                if (x >= to_delete[y]) {
                    data[4*(y*width + x) + 0] = data[4*(y*width + x+1) + 0];
                    data[4*(y*width + x) + 1] = data[4*(y*width + x+1) + 1];
                    data[4*(y*width + x) + 2] = data[4*(y*width + x+1) + 2];
                    data[4*(y*width + x) + 3] = data[4*(y*width + x+1) + 3];
                }
            }
            data[4*(y*width + cur_width-1) + 0] = 255;
            data[4*(y*width + cur_width-1) + 1] = 255;
            data[4*(y*width + cur_width-1) + 2] = 255;
            data[4*(y*width + cur_width-1) + 3] = 255;
        }
        cur_width--;
    }
    
    free(dp);
    free(direction);
    free(to_delete);
    free(energy);
}

+ (void) resizer:(CGImageRef)imageRef withData:(unsigned char *)data
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    double *gradient = [ImageHelper getGradientMatrixForImage:imageRef withData:data];
    double *expandedGradient = [ImageHelper expandedGradientForImage:imageRef withGradient:gradient];
    
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

+ (double *)expandedGradientForImage:(CGImageRef)imageRef withGradient:(double *)gradient
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
    
+ (UIImage *)modifyImage:(UIImage *)image withOperator:(ImageOperator *)operator
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
    
    [operator changeImage:imageRef withData:rawData];
    
    imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    free(rawData);
    
    //[NSData dataWithBytesNoCopy:rawData length:width * height];
    
    return newImage;
}

+ (unsigned char *) getRawDataFromImage:(CGImageRef)imageRef
{
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
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return rawData;
}

+ (UIImage *)modifyImageSeamCarvingShrinkVertical:(UIImage*)image atHeight:(int)cur_height shrinkBy: (int)reduced_height
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
    
    [ImageHelper resizerSeamCarvingShrinkVertical:imageRef withData:rawData atHeight:cur_height shrinkBy:reduced_height];
    
    imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    free(rawData);
    
    //[NSData dataWithBytesNoCopy:rawData length:width * height];
    
    return newImage;
}

+ (void) resizerSeamCarvingShrinkVertical:(CGImageRef)imageRef withData:(unsigned char *)data atHeight:(int)cur_height shrinkBy:(int) reduced_height
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    // prepare data for dynamic programming
    double *energy = calloc(width*height , sizeof(double));
    double *dp = calloc(width*height, sizeof(double));
    int *direction = calloc(width*height, sizeof(int));
    uint32_t *to_delete = calloc(width, sizeof(uint32_t));
    uint8_t r, g, b;
    
    // dynamic programming
    for (int y = 0; y < cur_height; y++){
        dp[y * width + 0] = 0.0;
    }
    
    while (reduced_height--) {
        for (int x = 0; x < width; x++) {
            for (int y= 0; y < cur_height; y++) {
                // calculate the intensity with parameters:
                // 0.2989, 0.5870, 0.1140
                r = data[4 * (y * width + x) + 0];
                g = data[4 * (y * width + x) + 1];
                b = data[4 * (y * width + x) + 2];
                energy[y * width + x] = 0.2989*r + 0.5870*g + 0.1140*b;
            }
        }
        
        for (int x = 1; x < width; x++) {
            for (int y = 0; y < cur_height; y++) {
                dp[y*width + x] = 999999.9;
                for (int y_delta = -1; y_delta <= 1; y_delta++) {
                    if (y+y_delta >=0 && y+y_delta<cur_height) {
                        double new_value = dp[(y+y_delta)*width + (x-1)] +
                            fabs(energy[y*width + x] - energy[(y+y_delta)*width + x-1]);
                        if (new_value < dp[y*width + x]) {
                            dp[y*width + x] = new_value;
                            direction[y*width + x] = y_delta;
                        }
                    }
                }
            }
        }

        double bottom_min_energy = 999999.9;
        for (int y = 0; y < cur_height; y++) {
            if (dp[width * y + width-1] < bottom_min_energy) {
                to_delete[width-1] = y;
                bottom_min_energy = dp[width * y + width-1];
            }
        }
        for (int x = (int)width-2; x>=0; x--) {
            to_delete[x] = to_delete[x+1] + direction[to_delete[x+1]*width + x+1];
        }
  
        // modify image data
        for (int x = 0; x<width; x++) {
            for (int y = 0; y < cur_height-1; y++) {
                if (y >= to_delete[x]) {
                    data[4*(y*width + x) + 0] = data[4*((y+1)*width + x) + 0];
                    data[4*(y*width + x) + 1] = data[4*((y+1)*width + x) + 1];
                    data[4*(y*width + x) + 2] = data[4*((y+1)*width + x) + 2];
                    data[4*(y*width + x) + 3] = data[4*((y+1)*width + x) + 3];
                }
            }
            data[4*((cur_height-1)*width + x) + 0] = 255;
            data[4*((cur_height-1)*width + x) + 1] = 255;
            data[4*((cur_height-1)*width + x) + 2] = 255;
            data[4*((cur_height-1)*width + x) + 3] = 255;
        }
        cur_height--;
    }
    
    free(dp);
    free(direction);
    free(to_delete);
    free(energy);
    
}

+ (UIImage *)modifyImageSeamCarvingEnlargeVertical:(UIImage*)image enlargeBy: (int)added_height {
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc((height+added_height) * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height + added_height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    
    CGContextDrawImage(context, CGRectMake(0, 0+added_height, width, height), imageRef);
    //CGContextRelease(context);
    
    [ImageHelper resizerSeamCarvingEnlargeVertical:imageRef withData:rawData enlargeBy:added_height];
    imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    free(rawData);
    //[NSData dataWithBytesNoCopy:rawData length:width * height];
    
    return newImage;
}

+ (void) resizerSeamCarvingEnlargeVertical:(CGImageRef)imageRef withData:(unsigned char *)data enlargeBy:(int) added_height
{
    int width = CGImageGetWidth(imageRef);
    int height = CGImageGetHeight(imageRef);
    // prepare data for dynamic programming
    double *energy = calloc(width*(height+added_height) , sizeof(double));
    double *dp = calloc(width*(height+added_height), sizeof(double));
    int *direction = calloc(width*(height+added_height), sizeof(int));
    int *to_repeat_from = calloc(added_height, sizeof(int)); // selected cells on the right-most column
    int *repeat_times = calloc(width*height, sizeof(int));
    uint8_t r, g, b;
    
    // dynamic programming
    for (int y = 0; y < height + added_height; y++){
        dp[y * width + 0] = 0.0;
    }
    

    for (int x = 0; x < width; x++) {
        for (int y= 0; y < height; y++) {
            // calculate the intensity with parameters:
            // 0.2989, 0.5870, 0.1140
            r = data[4 * (y * width + x) + 0];
            g = data[4 * (y * width + x) + 1];
            b = data[4 * (y * width + x) + 2];
            energy[y * width + x] = 0.2989*r + 0.5870*g + 0.1140*b;
        }
    }
    
    for (int x = 1; x < width; x++) {
        for (int y = 0; y < height; y++) {
            dp[y*width + x] = 999999.9;
            for (int y_delta = -1; y_delta <= 1; y_delta++) {
                if (y+y_delta >= 0 && y+y_delta < height) {
                    double new_value = dp[(y+y_delta)*width + (x-1)] +
                    fabs(energy[y*width + x] - energy[(y+y_delta)*width + x-1]);
                    if (new_value < dp[y*width + x]) {
                        dp[y*width + x] = new_value;
                        direction[y*width + x] = y_delta;
                    }
                }
            }
        }
    }
    
    // select added_height number of smallest numbers
    for (int i = 0; i < added_height; i++) {
        to_repeat_from[i] = -1;
    }
    for (int y = 0; y < height; y++) {
        for (int i=0; i < added_height; i++) {
            if ((to_repeat_from[i]==-1) || (dp[width*y + width-1] < dp[width*to_repeat_from[i] + width-1])) {
                for (int j=added_height-1; j>i; j--) {
                    to_repeat_from[j] = to_repeat_from[j-1];
                }
                to_repeat_from[i] = y;
                break;
            }
        }
        int a0 = to_repeat_from[0];
        int a1 = to_repeat_from[1];
        int a2 = to_repeat_from[2];
        int a3 = to_repeat_from[3];
        int a4 = to_repeat_from[4];
        int a5 = to_repeat_from[5];
        int a6 = to_repeat_from[6];
//        double b0 = dp[width-1 + width * 0];
//        double b1 = dp[width-1 + width * 1];
//        double b2 = dp[width-1 + width * 2];
//        double b3 = dp[width-1 + width * 3];
//        double b4 = dp[width-1 + width * 4];
//        double b5 = dp[width-1 + width * 5];
    }
    
    int a0 = to_repeat_from[0];
    int a1 = to_repeat_from[1];
    int a2 = to_repeat_from[2];
    int a3 = to_repeat_from[3];
    int a4 = to_repeat_from[4];
    int a5 = to_repeat_from[5];
    int a6 = to_repeat_from[6];
    
    // generate repeat_times matrix
    for (int y = 0; y<height; y++) {
        for (int x = 0; x<width; x++) {
            repeat_times[y*width + x] = 1;
        }
    }
    for (int i = 0; i<added_height; i++) {
        int x = width-1;
        int y = to_repeat_from[i];
        repeat_times[y*width + x] += 1;
        for (x = width-2; x>=0; x--) {
            y = direction[y*width + x+1] + y;
            repeat_times[y*width + x] += 1;
        }
    }
    // repeated the pixels
    for (int x = 0; x < width; x++) {
        int y2 = height + added_height - 1; // index for new matrix
        for (int y1 = height-1; y1>=0; y1--) {
            for (int i=0; i<repeat_times[y1*width + x]; i++) {
                data[4*(y2*width + x) + 0] = data[4*(y1*width + x) + 0];
                data[4*(y2*width + x) + 1] = data[4*(y1*width + x) + 1];
                data[4*(y2*width + x) + 2] = data[4*(y1*width + x) + 2];
                data[4*(y2*width + x) + 3] = data[4*(y1*width + x) + 3];
                y2--;
            }
        }
    }
    
    free(dp);
    free(direction);
    free(to_repeat_from);
    free(energy);
    free(repeat_times);
}

// TODO: add face-detection

@end
























