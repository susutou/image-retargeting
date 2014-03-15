//
//  ImageHelper.h
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/13/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageHelper : NSObject

+ (NSArray *)getRGBAsFromImage:(UIImage *)image atX:(int)xx andY:(int)yy count:(int)count;
+ (UIImage *)modifyImage:(UIImage *)image;
//+ (void) resizer:(CGImageRef)imageRef withData:(unsigned char *)data;
+ (UIImage *)modifyImageSeamCarvingShrinkHorizonal:(UIImage*)image;

@end
