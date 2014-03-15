//
//  RetargetingSolver.h
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/14/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIImage+Resize.h"
#import "ImageHelper.h"
#import "Matrix.h"
#import "GradientOperator.h"

@interface RetargetingSolver : NSObject

@property (nonatomic) int numRows;  // number of grid rows
@property (nonatomic) int numCols;  // number of grid columns
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic) int height;
@property (nonatomic) int width;

@property (nonatomic, strong) UIImage *saliencyImage;

@property (nonatomic) unsigned char *imageRawData;
@property (nonatomic) double *gradient;

@property (nonatomic, strong) Matrix *saliencyMatrix;

- (id) initWithImage:(UIImage *)image;

@end
