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
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    CGSize newSize = CGSizeMake(width * scale, height * scale);
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
