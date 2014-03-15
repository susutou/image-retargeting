//
//  ViewController.m
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/13/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import "ViewController.h"
#import "ImageHelper.h"
#import "UIImage+Resize.h"

@interface ViewController ()
@property int cur_effective_width;
@end

@implementation ViewController

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

#pragma - UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    self.imageView.image = [UIImage imageWithUIImage:chosenImage withScale:0.2];
    
    //NSArray* pixelData = [[NSArray alloc] initWithArray:[ImageHelper getRGBAsFromImage:chosenImage atX:0 andY:0 count:1]];
    //UIColor* initialColor = [[UIColor alloc] init];
    //initialColor = pixelData[0];
    
    //float red, green, blue, alpha;
    //[initialColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma - Mark button events

// action for photo taking button
- (IBAction)takePhoto:(UIButton *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
    self.cur_effective_width = -1;
}

// action for photo selecting button
- (IBAction)selectPhoto:(UIButton *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
    self.cur_effective_width = -1;
}

- (IBAction)shrinkImage:(UIButton *)sender {
    
    self.imageView.image = [ImageHelper modifyImage:self.imageView.image];
    
}

- (IBAction)seamCarvingShrinkHorizonal:(UIButton *)sender {
    if (self.cur_effective_width == -1) {
        self.cur_effective_width = self.imageView.image.size.width;
    }
    const int kC_width_to_reduce = 10;
    self.imageView.image = [ImageHelper modifyImageSeamCarvingShrinkHorizonal:self.imageView.image atWidth:self.cur_effective_width shringBy:kC_width_to_reduce];
    self.cur_effective_width -= kC_width_to_reduce;
}
@end
