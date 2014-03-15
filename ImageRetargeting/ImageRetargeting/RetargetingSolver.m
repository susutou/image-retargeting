//
//  RetargetingSolver.m
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/14/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import "RetargetingSolver.h"

#define LONG_EDGE 200
#define M 25
#define N 25

@implementation RetargetingSolver

- (id) init
{
    self = [super init];
    if (self != nil) {
        // TODO
    }
    
    return self;
}

- (id) initWithImage:(UIImage *)image
{
    self = [super init];
    if (self != nil) {
        self.originalImage = image;
        self.saliencyImage = [UIImage imageWithUIImage:image withLongEdgeAs:LONG_EDGE];
        self.numRows = M;
        self.numCols = N;
        self.height = CGImageGetHeight(image.CGImage);
        self.width = CGImageGetWidth(image.CGImage);
        
        CGImageRef imageRef = self.saliencyImage.CGImage;
        
        self.imageRawData = [ImageHelper getRawDataFromImage:imageRef];
        double *gradient = [ImageHelper getGradientMatrixForImage:imageRef withData:self.imageRawData];
        self.gradient = [ImageHelper expandedGradientForImage:imageRef withGradient:gradient];
        
        [self calculateSaliencyMatrix];
        
        GradientOperator *operator = [[GradientOperator alloc] init];
        operator.gradient = self.gradient;
        
        self.saliencyImage = [ImageHelper modifyImage:self.saliencyImage withOperator:operator];
        
        free(gradient);
    }
    
    return self;
}

- (void)calculateSaliencyMatrix
{
    CGImageRef imageRef = self.saliencyImage.CGImage;
    
    int height = CGImageGetHeight(imageRef);
    int width = CGImageGetWidth(imageRef);
    
    int cellHeight = height / self.numRows;
    int cellWidth = width / self.numCols;
    
    int max = 0;
    
    self.saliencyMatrix = [[Matrix alloc] initWithSizeRows:self.numRows andColumns:self.numCols];
    [self.saliencyMatrix setAllEntriesToValue:0];
    
    for (int i = 0; i < self.numRows; i++) {
        for (int j = 0; j < self.numCols; j++) {
            int average = 0;
            
            for (int iCell = 0; iCell < cellHeight; iCell++) {
                for (int jCell = 0; jCell < cellWidth; jCell++) {
                    int iGlobal = i * cellHeight + iCell;
                    int jGlobal = j * cellWidth + jCell;
                    int k = iGlobal * width + jGlobal;
                    
                    average = average + self.gradient[k];
                }
            }
            
            average = average / (cellHeight * cellWidth);
            [self.saliencyMatrix setEntryAtRow:i andColumn:j toValue:average];
            
            if (average > max) {
                max = average;
            }
        }
    }
    
    for (int i = 0; i < self.numRows; i++) {
        for (int j = 0; j < self.numCols; j++) {
            for (int iCell = 0; iCell < cellHeight; iCell++) {
                for (int jCell = 0; jCell < cellWidth; jCell++) {
                    int iGlobal = i * cellHeight + iCell;
                    int jGlobal = j * cellWidth + jCell;
                    int k = iGlobal * width + jGlobal;
                    
                    self.gradient[k] = 250 * [self.saliencyMatrix entryAtRow:i andColumn:j] / max;
                }
            }
        }
    }
}

- (void)resizeToHeight:(int)targetHeight width:(int)targetWidth
{
    double sourceRatio = 1.0 * self.width / self.height;
    double targetRatio = 1.0 * targetWidth / targetHeight;
    
    int minCellHeight = 0;
    int minCellWidth = 0;
    
    double L = 0.7;
    
    if (targetRatio > sourceRatio) {
        minCellWidth = L * sourceRatio * targetHeight / self.numCols;
        minCellHeight = L * targetHeight / self.numRows;
    } else {
        minCellWidth = L * targetWidth / self.numCols;
        minCellHeight = L / sourceRatio * targetWidth / self.numRows;
    }
    
    NSLog(@"minCellHeight = %d, minCellWidth = %d", minCellHeight, minCellWidth);
    
    // solve naive retargeting
    
}

@end
