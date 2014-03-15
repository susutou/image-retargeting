//
//  UIImage+Resize.m
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/14/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

+(UIImage *)imageWithUIImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)imageWithUIImage:(UIImage *)image withScale:(CGFloat)scale
{
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = 0, height = 0;
    int orientation = image.imageOrientation;
    
    if (orientation == 0) {
        width = CGImageGetWidth(imageRef);
        height = CGImageGetHeight(imageRef);
    } else {
        width = CGImageGetHeight(imageRef);
        height = CGImageGetWidth(imageRef);
    }
    
    CGSize newSize = CGSizeMake(width * scale, height * scale);
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)imageWithUIImage:(UIImage *)image withLongEdgeAs:(int)length
{
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = 0, height = 0;
    int orientation = image.imageOrientation;
    
    if (orientation == 0) {
        width = CGImageGetWidth(imageRef);
        height = CGImageGetHeight(imageRef);
    } else {
        width = CGImageGetHeight(imageRef);
        height = CGImageGetWidth(imageRef);
    }
    
    if (width > height) {
        height = 200 * ((double) height / width);
        width = 200;
    } else {
        width = 200 * ((double) width / height);
        height = 200;
    }
    
    // NSLog(@"Width: %d, Height: %d", width, height);
    
    CGSize newSize = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
