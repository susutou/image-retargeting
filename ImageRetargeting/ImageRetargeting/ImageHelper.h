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
+ (UIImage *)modifyImage:(UIImage *)image;

+ (UIImage *)modifyImage:(UIImage *)image withOperator:(ImageOperator *)operator;

+ (unsigned char *) getRawDataFromImage:(CGImageRef)imageRef;
+ (double *) getGradientMatrixForImage:(CGImageRef)imageRef withData:(unsigned char *)data;
+ (double *)expandedGradientForImage:(CGImageRef)imageRef withGradient:(double *)gradient;

+ (UIImage *)modifyImageSeamCarvingShrinkHorizonal:(UIImage*)image atWidth:(int)cur_width shrinkBy: (int)reduced_width;
+ (UIImage *)modifyImageSeamCarvingShrinkVertical:(UIImage*)image atHeight:(int)cur_height shrinkBy: (int)reduced_height;
+ (UIImage *)modifyImageSeamCarvingEnlargeVertical:(UIImage*)image enlargeBy: (int)added_height;

@end
