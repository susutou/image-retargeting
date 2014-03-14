//
//  XYZViewController.m
//  CameraApp
//
//  Created by zhe-mac on 14-3-13.
//  Copyright (c) 2014年 zhe-mac. All rights reserved.
//

#import "XYZViewController.h"
#import "XYZImageHelper.h"

@interface XYZViewController ()

@end

@implementation XYZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 + (NSArray *)getRGBAsFromImage:(UIImage *)image atX:(int)xx andY:(int)yy count:(int)count
 {
 NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
 
 // First get the image into your data buffer
 CGImageRef imageRef = [image CGImage];
 NSUInteger width = CGImageGetWidth(imageRef);
 NSUInteger height = CGImageGetHeight(imageRef);
 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
 unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
 NSUInteger bytesPerPixel = 4;
 NSUInteger bytesPerRow = bytesPerPixel * width;
 NSUInteger bitsPerComponent = 8;
 CGContextRef context = CGBitmapContextCreate(rawData, width, height,
 bitsPerComponent, bytesPerRow, colorSpace,
 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
 CGColorSpaceRelease(colorSpace);
 
 CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
 CGContextRelease(context);
 
 // Now your rawData contains the image data in the RGBA8888 pixel format.
 int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
 for (int ii = 0 ; ii < count ; ++ii)
 {
 CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
 CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
 CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
 CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
 byteIndex += 4;
 
 UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
 [result addObject:acolor];
 }
 
 free(rawData);
 
 return result;
 }*/



- (IBAction)selectPhoto:(UIButton *)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)modifyImage:(UIButton *)sender {
    UIImage* curImage = self.imageView.image;
    
    CGImageRef imageRef = [curImage CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    unsigned char *rawData = [XYZImageHelper getRGBAsFromImage:curImage atX:0 andY:0 count:width*height];

    int tmp_a = width * height;
    int tmp_b = tmp_a * 4;
    int tmp_c = sizeof(rawData);

    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            if (col + 500 > width) {
                rawData[4 * (row*width + col) + 0] = 255;
//                rawData[4 * (row*width + col) + 1] = 1.0;
//                rawData[4 * (row*width + col) + 2] = 1.0;
//                rawData[4 * (row*width + col) + 3] = 1.0;
            }
            
        }
    }
    
    // create a new image from the modified pixel data
    size_t bitsPerComponent         = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel             = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow              = CGImageGetBytesPerRow(imageRef);
    
    CGColorSpaceRef colorspace      = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo         = CGImageGetBitmapInfo(imageRef);
    CGDataProviderRef provider      = CGDataProviderCreateWithData(NULL, rawData, width*height*4, NULL);
    
    CGImageRef newImageRef = CGImageCreate (
                                            width,
                                            height,
                                            bitsPerComponent,
                                            bitsPerPixel,
                                            bytesPerRow,
                                            colorspace,
                                            bitmapInfo,
                                            provider,
                                            NULL,
                                            false,
                                            kCGRenderingIntentDefault
                                            );
    // the modified image
    UIImage *outImage   = [UIImage imageWithCGImage:newImageRef];
    
    // cleanup
    // free(rawData); // ???
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    CGImageRelease(newImageRef);
    
    self.imageView.image = outImage;
}

- (IBAction)takePhoto:(UIButton *)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated: YES completion: NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    self.imageView.image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}


@end
