//
//  UIImage+Resize.h
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/14/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

@interface UIImage (Resize)

+ (UIImage *)imageWithUIImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)imageWithUIImage:(UIImage *)image withScale:(CGFloat)scale;

@end
