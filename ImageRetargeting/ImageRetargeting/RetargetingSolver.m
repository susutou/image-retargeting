//
//  RetargetingSolver.m
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/14/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import "RetargetingSolver.h"

#define LONG_EDGE 400
#define M 25
#define N 25
#define FACE_DETECTION_SCALE 4

@implementation RetargetingSolver

- (id)init
{
    self = [super init];
    if (self != nil) {
        // TODO
    }
    
    return self;
}

- (void)dealloc
{
    free(self.gradient);
}

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self != nil) {
        self.originalImage = [UIImage imageWithUIImage:image withLongEdgeAs:600];
        //self.faceDetectionImage = [UIImage imageWithUIImage:image withLongEdgeAs:FACE_DETECTION_SCALE * LONG_EDGE];
        self.saliencyImage = [UIImage imageWithUIImage:image withLongEdgeAs:LONG_EDGE];
        self.numRows = M;
        self.numCols = N;
        self.height = CGImageGetHeight(self.originalImage.CGImage);
        self.width = CGImageGetWidth(self.originalImage.CGImage);
        self.currentHeight = self.height;
        self.currentWidth = self.width;
        
        CGImageRef imageRef = self.saliencyImage.CGImage;
        
        self.imageRawData = [ImageHelper getRawDataFromImage:imageRef];
        double *gradient = [self getGradientMatrixForImage:imageRef withData:self.imageRawData];
        self.gradient = [self expandedGradientForImage:imageRef withGradient:gradient];
        
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
            double average = 0;
            
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
    
    double minCellHeight = 0;
    double minCellWidth = 0;
    
    double LFactor = 0.7;
    double croppingFactorAlpha = 0.5;
    
    double laplacianRegularizationWeight = 0.0;

    Matrix *omega = self.saliencyMatrix;
    
    if (targetRatio > sourceRatio) {
        minCellWidth = 1.0 * LFactor * sourceRatio * targetHeight / self.numCols;
        minCellHeight = 1.0 * LFactor * targetHeight / self.numRows;
    } else {
        minCellWidth = 1.0 * LFactor * targetWidth / self.numCols;
        minCellHeight = 1.0 * LFactor / sourceRatio * targetWidth / self.numRows;
    }
    
    NSLog(@"minCellHeight = %f, minCellWidth = %f", minCellHeight, minCellWidth);
    
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
    
//    [sRows printMatrixWithName:@"sRows"];
//    [sCols printMatrixWithName:@"sCols"];
    
    // second pass, with cropping
    double wLow = (1 + croppingFactorAlpha) / 2.0 * minCellWidth;
    double wHigh = (1 + 1.0 / LFactor) / 2.0 * minCellWidth;
    
    double hLow = (1 + croppingFactorAlpha) / 2.0 * minCellHeight;
    double hHigh = (1 + 1.0 / LFactor) / 2.0 * minCellHeight;
    
    [minH setAllEntriesToValue:minCellHeight];
    for (int i = 0; i < M; i++) {
        double cropHeightBound = (i - 1) * 1.0 / N * hLow + (1 - (i - 1) * 1.0 / N) * hHigh;
        if ([sRows entryAtIndex:i] < cropHeightBound) {
            [minH setEntryAtIndex:i toValue:0];
            [maxH setEntryAtIndex:i toValue:0];
        }
    }
    
//    for (int i = 0; i < M; i++) {
//        if ([sRows entryAtIndex:i] <= minCellHeight) {
//            [minH setEntryAtIndex:i toValue:0];
//            [maxH setEntryAtIndex:i toValue:0];
//        } else {
//            break;
//        }
//    }
//    
//    for (int i = M - 1; i >= 0; i--) {
//        if ([sRows entryAtIndex:i] <= minCellHeight) {
//            [minH setEntryAtIndex:i toValue:0];
//            [maxH setEntryAtIndex:i toValue:0];
//        } else {
//            break;
//        }
//    }
    
    [minW setAllEntriesToValue:minCellWidth];
    for (int j = 0; j < N; j++) {
        double cropWidthBound = (j - 1) * 1.0 / N * wLow + (1 - (j - 1) * 1.0 / N) * wHigh;
        if ([sCols entryAtIndex:j] < cropWidthBound) {
            [minW setEntryAtIndex:j toValue:0];
            [maxW setEntryAtIndex:j toValue:0];
        }
    }
    
//    for (int j = 0; j < N; j++) {
//        if ([sCols entryAtIndex:j] <= minCellWidth) {
//            [minW setEntryAtIndex:j toValue:0];
//            [maxW setEntryAtIndex:j toValue:0];
//        } else {
//            break;
//        }
//    }
//    
//    for (int j = N - 1; j >= 0; j--) {
//        if ([sCols entryAtIndex:j] <= minCellWidth) {
//            [minW setEntryAtIndex:j toValue:0];
//            [maxW setEntryAtIndex:j toValue:0];
//        } else {
//            break;
//        }
//    }
    
    solution = [self.rangeSolver solveWithS:QRawData B:sRawData W:targetWidth H:targetHeight
                                       minW:[minW rawDataVector]
                                       maxW:[maxW rawDataVector]
                                       minH:[minH rawDataVector]
                                       maxH:[maxH rawDataVector]];
    
    sRows = [[Matrix alloc] initFromColumnMajorData:(solution + M) withRows:N andColumns:1];
    sCols = [[Matrix alloc] initFromColumnMajorData:solution withRows:M andColumns:1];
    
//    [sRows printMatrixWithName:@"sRows"];
//    [sCols printMatrixWithName:@"sCols"];
    
    self.retargetedImage = [self generateRetargetedImageFromVectorColumn:[sCols rawDataVector] row:[sRows rawDataVector]];
}

- (UIImage *)generateRetargetedImageFromVectorColumn:(double *)sCol row:(double *)sRow
{
    CGSize size = CGSizeMake(self.currentWidth, self.currentHeight);
    // CGSize size = CGSizeMake(self.width, self.height);
    
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

- (void)markFacesInGradientMatrix:(double *)gradient forImage:(CGImageRef)imageRef
{
    int height = CGImageGetHeight(imageRef);
    int width = CGImageGetWidth([[self saliencyImage] CGImage]);
    
    CIImage *imageForDetection = [CIImage imageWithCGImage:imageRef];
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil
                                              options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    
    NSArray *features = [detector featuresInImage:imageForDetection];
    
    for (CIFaceFeature *faceFeature in features) {
        int x = faceFeature.bounds.origin.x;
        int y = faceFeature.bounds.origin.y;
        int boundHeight = faceFeature.bounds.size.height;
        int boundWidth = faceFeature.bounds.size.width;
        
        NSLog(@"x = %d, y = %d", x, y);
        
        for (int i = x; i < x + boundHeight; i++) {
            for (int j = y; j < y + boundWidth; j++) {
                gradient[(height - j - 1) * width + i] = 250;
            }
        }
        
        int hairStartX = x;
        int hairStartY = y;
        int hairEndX = x + boundWidth;
        hairEndX = hairEndX > width - 1 ? width - 1 : hairEndX;
        int hairEndY = y + boundHeight * 1.5;
        hairEndY = hairEndY > height - 1 ? height - 1 : hairEndY;
        
        for (int i = hairStartX; i < hairEndX; i++) {
            for (int j = hairStartY; j < hairEndY; j++) {
                gradient[(height - j - 1) * width + i] = 250;
            }
        }
        
        int bodyStartX = x - boundWidth;
        bodyStartX = bodyStartX < 0 ? 0 : bodyStartX;
        int bodyStartY = 0;
        int bodyEndX = x + boundWidth + boundWidth;
        bodyEndX = bodyEndX > width - 1 ? width - 1 : bodyEndX;
        int bodyEndY = y;
        
        for (int i = bodyStartX; i < bodyEndX; i++) {
            for (int j = bodyStartY; j < bodyEndY; j++) {
                gradient[(height - j - 1) * width + i] = 250;
            }
        }
    }
    
    // try to mark hair and body?
    // hair: (x, y + faceHeight) -> (x + faceWidth, y + (1 + 1/3) * faceHeight)
    // body: (x - faceWidth, 0) -> (x + faceWidth, y)
}

- (double *)getGradientMatrixForImage:(CGImageRef)imageRef withData:(unsigned char *)data
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    double *grayscaleData = calloc(height * width, sizeof(double));
    
    // convert the image to grayscale
    for (int i = 0; i < width * height; i += 1) {
        int r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2];
        double intensity = r * 0.2989 + g * 0.5870 + b * 0.1140;
        grayscaleData[i] = intensity;
    }
    
    double *xGradient = calloc(height * width, sizeof(double));
    double *yGradient = calloc(height * width, sizeof(double));
    double *gradient = calloc(height * width, sizeof(double));
    
    double A[3][3];
    
    for (int i = 1; i < width - 1; i++) {
        for (int j = 1; j < height - 1; j++) {
            A[0][0] = grayscaleData[(j - 1) * width + (i - 1)];
            A[0][1] = grayscaleData[(j) * width + (i - 1)];
            A[0][2] = grayscaleData[(j + 1) * width + (i - 1)];
            A[1][0] = grayscaleData[(j - 1) * width + (i)];
            A[1][1] = grayscaleData[(j) * width + (i)];
            A[1][2] = grayscaleData[(j + 1) * width + (i)];
            A[2][0] = grayscaleData[(j - 1) * width + (i + 1)];
            A[2][1] = grayscaleData[(j) * width + (i + 1)];
            A[2][2] = grayscaleData[(j + 1) * width + (i + 1)];
            
            NSUInteger k = j * width + i;
            
            // compute Sobel kernel gradient
            xGradient[k] = -1 * A[0][0] - 2 * A[1][0] - 1 * A[2][0] + 1 * A[0][2] + 2 * A[1][2] + 1 * A[2][2];
            yGradient[k] = -1 * A[0][0] - 2 * A[0][1] - 1 * A[0][2] + 1 * A[2][0] + 2 * A[2][1] + 1 * A[2][2];
            gradient[k] = sqrt(xGradient[k] * xGradient[k] + yGradient[k] * yGradient[k]);
            
        }
    }
    
    // normalizing gradient
    double maxGradient = 0;
    
    for (int i = 0; i < width * height; i++) {
        if (gradient[i] > maxGradient) {
            maxGradient = gradient[i];
        }
    }
    
    for (int i = 0; i < width * height; i++) {
        gradient[i] = gradient[i] / maxGradient * 250;
    }
    
    // TODO: face-detection
    [self markFacesInGradientMatrix:gradient forImage:imageRef];
    
    free(grayscaleData);
    free(xGradient);
    free(yGradient);
    
    return gradient;
}

- (double *)expandedGradientForImage:(CGImageRef)imageRef withGradient:(double *)gradient
{
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    double *expandedGradient = calloc(height * width, sizeof(double));
    int d = 4;  // stroke width
    
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            NSUInteger k = j * width + i;
            for (int dx = -d; dx <= d; dx++) {
                for (int dy = -d; dy < d; dy++) {
                    double dist = sqrt(dx * dx + dy * dy);
                    if (dist <= d) {
                        int xn = i + dx;
                        int yn = j + dy;
                        if (0 <= xn && xn < width && 0 <= yn && yn < height) {
                            expandedGradient[k] = MAX(expandedGradient[k], (0.5 + 0.5 * (d * d - dist * dist) / (d * d)) * gradient[yn * width + xn]);
                        }
                    }
                }
            }
        }
    }
    
    return expandedGradient;
}


@end




















