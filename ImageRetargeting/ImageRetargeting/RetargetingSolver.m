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
        self.originalImage = [UIImage imageWithUIImage:image withLongEdgeAs:600];
        self.saliencyImage = [UIImage imageWithUIImage:image withLongEdgeAs:LONG_EDGE];
        self.numRows = M;
        self.numCols = N;
        self.height = CGImageGetHeight(self.originalImage.CGImage);
        self.width = CGImageGetWidth(self.originalImage.CGImage);
        self.currentHeight = self.height;
        self.currentWidth = self.width;
        
        CGImageRef imageRef = self.saliencyImage.CGImage;
        
        self.imageRawData = [ImageHelper getRawDataFromImage:imageRef];
        double *gradient = [ImageHelper getGradientMatrixForImage:imageRef withData:self.imageRawData];
        self.gradient = [ImageHelper expandedGradientForImage:imageRef withGradient:gradient];
        
        [self calculateSaliencyMatrix];
        
        GradientOperator *operator = [[GradientOperator alloc] init];
        operator.gradient = self.gradient;
        
        self.saliencyImage = [ImageHelper modifyImage:self.saliencyImage withOperator:operator];
        
        self.rangeSolver = [[CVXGenRangeSolver25x25 alloc] init];
        
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
    
    int W = self.width;
    int H = self.height;
    
    int minCellHeight = 0;
    int minCellWidth = 0;
    
    double LFactor = 0.7;
    double croppingFactorAlpha = 0.5;
    
    double laplacianRegularizationWeight = 0.0;

    Matrix *omega = self.saliencyMatrix;
    
    if (targetRatio > sourceRatio) {
        minCellWidth = LFactor * sourceRatio * targetHeight / self.numCols;
        minCellHeight = LFactor * targetHeight / self.numRows;
    } else {
        minCellWidth = LFactor * targetWidth / self.numCols;
        minCellHeight = LFactor / sourceRatio * targetWidth / self.numRows;
    }
    
    NSLog(@"minCellHeight = %d, minCellWidth = %d", minCellHeight, minCellWidth);
    
    // solve naive retargeting
    // vector s
    Matrix *s = [[Matrix alloc] initWithSizeRows:(M + N) andColumns:1];
    // matrix K' * K
    Matrix *Q;
    // matrix K
    FastCCSMatrix *K = [[FastCCSMatrix alloc] initWithSizeRows:(M * N) columns:(M + N) andMaxColSize:(M + N)];

    // build ASAP matrix
    double w = sqrt(1 - laplacianRegularizationWeight);
    
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < M; j++) {
            int row = i * M + j;
            [K setEntryAtRow:row andColumn:i toValue:(1.0 * w * [omega entryAtRow:j andColumn:i] * N / W)];
            [K setEntryAtRow:row andColumn:(j + M) toValue:(-1.0 * w * [omega entryAtRow:j andColumn:i] * M / H)];
        }
    }
    
    // add laplacian term
    FastCCSMatrix *L = [[FastCCSMatrix alloc] initWithSizeRows:(M + N) columns:(M + N) andMaxColSize:2];
    double lW = 1.0 * N / W * sqrt(laplacianRegularizationWeight);
    for(int i = 0; i < M - 1; i++) {
        [L setEntryAtRow:i andColumn:i toValue:-lW];
        [L setEntryAtRow:i andColumn:(i + 1) toValue:lW];
    }
    
    double lH = 1.0 * M / H * sqrt(laplacianRegularizationWeight);
    for (int i = 0; i < N - 1; i++) {
        [L setEntryAtRow:(M + i) andColumn:(M + i) toValue:-lH];
        [L setEntryAtRow:(M + i) andColumn:(M + i + 1) toValue:lH];
    }
    
    //calculate Q = K' * K + L
    Q = [[K innerProduct] add:[L innerProduct]];
    
    double *solution;
    double *QRawData = [Q rawDataAsColumnMajor];  // the actual data array underlying Q matrix
    double *sRawData = [s rawDataAsColumnMajor];
    
    Matrix *minW = [[Matrix alloc] initVectorWithSize:N];
    [minW setAllEntriesToValue:minCellWidth * croppingFactorAlpha];
    
    Matrix *maxW = [[Matrix alloc] initVectorWithSize:N];
    [maxW setAllEntriesToValue:targetWidth];
    
    Matrix *minH = [[Matrix alloc] initVectorWithSize:M];
    [minH setAllEntriesToValue:minCellHeight * croppingFactorAlpha];
    
    Matrix *maxH = [[Matrix alloc] initVectorWithSize:M];
    [maxH setAllEntriesToValue:targetHeight];
    
    // first pass
    solution = [self.rangeSolver solveWithS:QRawData B:sRawData W:targetWidth H:targetHeight
                                       minW:[minW rawDataVector]
                                       maxW:[maxW rawDataVector]
                                       minH:[minH rawDataVector]
                                       maxH:[maxH rawDataVector]];
    
    Matrix *sRows = [[Matrix alloc] initFromColumnMajorData:(solution + M) withRows:N andColumns:1];
    Matrix *sCols = [[Matrix alloc] initFromColumnMajorData:solution withRows:M andColumns:1];
    
    [minW setAllEntriesToValue:minCellWidth];
    for (int i = 0; i < M; i++) {
        if ([sRows entryAtIndex:i] < minCellHeight) {
            [minH setEntryAtIndex:i toValue:0];
            [maxH setEntryAtIndex:i toValue:0];
        } else {
            break;
        }
    }
    
    for (int i = M - 1; i >= 0; i--) {
        if ([sRows entryAtIndex:i] < minCellHeight) {
            [minH setEntryAtIndex:i toValue:0];
            [maxH setEntryAtIndex:i toValue:0];
        } else {
            break;
        }
    }
    
    [minH setAllEntriesToValue:minCellHeight];
    for (int j = 0; j < N; j++) {
        if ([sCols entryAtIndex:j] < minCellWidth) {
            [minW setEntryAtIndex:j toValue:0];
            [maxW setEntryAtIndex:j toValue:0];
        }  else {
            break;
        }
    }
    
    for (int j = N - 1; j >= 0; j--) {
        if ([sCols entryAtIndex:j] < minCellWidth) {
            [minW setEntryAtIndex:j toValue:0];
            [maxW setEntryAtIndex:j toValue:0];
        }  else {
            break;
        }
    }
    
    solution = [self.rangeSolver solveWithS:QRawData B:sRawData W:targetWidth H:targetHeight
                                       minW:[minW rawDataVector]
                                       maxW:[maxW rawDataVector]
                                       minH:[minH rawDataVector]
                                       maxH:[maxH rawDataVector]];
    
    sRows = [[Matrix alloc] initFromColumnMajorData:(solution + M) withRows:N andColumns:1];
    sCols = [[Matrix alloc] initFromColumnMajorData:solution withRows:M andColumns:1];
    
    [sRows printMatrixWithName:@"sRows"];
    [sCols printMatrixWithName:@"sCols"];
    
    // TODO: add cropping into the retargeting process
    //
    
    self.retargetedImage = [self generateRetargetedImageFromVectorColumn:[sCols rawDataVector] row:[sRows rawDataVector]];
}

- (UIImage *)generateRetargetedImageFromVectorColumn:(double *)sCol row:(double *)sRow
{
    CGSize size = CGSizeMake(self.currentWidth, self.currentHeight);
    CGImageRef imageRef = self.originalImage.CGImage;
    
    UIGraphicsBeginImageContext(size);
    
    int accHeight = 0;
    int accWidth = 0;
    
    int cellWidth = self.width / N;
    int cellHeight = self.height / M;
    
    for (int i = 0; i < M; i++) {
        accWidth = 0;
        for (int j = 0; j < M; j++) {
            // crop rectangle
            CGRect cropRect = CGRectMake(j * cellWidth, i * cellHeight, cellWidth, cellHeight);
            
            // resize rectangle
            CGRect resizeRect = CGRectMake(accWidth, accHeight, sCol[j], sRow[i]);
            
            // image portion croped with cropRect
            CGImageRef imageCellRef = CGImageCreateWithImageInRect(imageRef, cropRect);
            UIImage *imageCell = [UIImage imageWithCGImage:imageCellRef];
            
            // draw image cell to context
            [imageCell drawInRect:resizeRect];
            
            accWidth += sCol[j];
        }
        accHeight += sRow[i];
    }
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

@end




















