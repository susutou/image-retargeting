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
    
    [operator changeImage:imageRef withData:rawData];
    
    imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    free(rawData);
    
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
    int *to_delete = calloc(width, sizeof(int)); // actually it is for repeation
    int *repeat_times = calloc(width*height, sizeof(int));
    int *mapped_coor = calloc(2*width*height, sizeof(int));
    unsigned char *data_copy = calloc(4*width*height, sizeof(unsigned char));
    memcpy(data_copy, data, 4*width*height);
    uint8_t r, g, b;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            mapped_coor[2 * (y*width + x) + 0] = x;
            mapped_coor[2 * (y*width + x) + 1] = y;
            repeat_times[y*width + x] = 1;
        }
    }
    
    // dynamic programming
    for (int y = 0; y < height; y++){
        dp[y * width + 0] = 0.0;
    }
    
    int cur_height = height;
    while (cur_height > height - added_height) {
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
        
        // mark the repeat position
        for (int x = 0; x<width; x++) {
            //repeat_times[to_delete[x] * width + x] += 1;
            int mapped_x = mapped_coor[2*(to_delete[x] * width + x) + 0];
            int mapped_y = mapped_coor[2*(to_delete[x] * width + x) + 1];
            repeat_times[mapped_y * width + mapped_x] += 1;
        }
        // shrink image data
        for (int x = 0; x<width; x++) {
            for (int y = 0; y < cur_height-1; y++) {
                if (y >= to_delete[x]) {
                    data[4*(y*width + x) + 0] = data[4*((y+1)*width + x) + 0];
                    data[4*(y*width + x) + 1] = data[4*((y+1)*width + x) + 1];
                    data[4*(y*width + x) + 2] = data[4*((y+1)*width + x) + 2];
                    data[4*(y*width + x) + 3] = data[4*((y+1)*width + x) + 3];
                    mapped_coor[2*(y*width + x) + 0] = mapped_coor[2*((y+1)*width + x) + 0];
                    mapped_coor[2*(y*width + x) + 1] = mapped_coor[2*((y+1)*width + x) + 1];
                }
            }
        }
        cur_height--;
    }// while
    
    // repeated the pixels
    memcpy(data, data_copy, 4*width*height);
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
    free(energy);
    free(repeat_times);
    free(mapped_coor);
    free(data_copy);
}

// TODO: add face-detection
@end
























