//
//  ImageHelper.h
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/13/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageOperator.h"

@interface ImageHelper : NSObject

+ (NSArray *)getRGBAsFromImage:(UIImage *)image atX:(int)xx andY:(int)yy count:(int)count;

+ (UIImage *)modifyImage:(UIImage *)image withOperator:(ImageOperator *)operator;

+ (unsigned char *) getRawDataFromImage:(CGImageRef)imageRef;

+ (UIImage *)modifyImageSeamCarvingShrinkHorizonal:(UIImage*)image atWidth:(int)cur_width shringBy: (int)reduced_width;
+ (UIImage *)modifyImageSeamCarvingShrinkVertical:(UIImage*)image atHeight:(int)cur_height shringBy: (int)reduced_height;

@end
