//
//  ViewController.m
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/13/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property int cur_effective_width;
@property int cur_effective_height;
@property UIImage* originalImageForSeamCarvingEnlarge;
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
    self.solver = [[RetargetingSolver alloc] initWithImage:chosenImage];
    
    self.imageView.image = [UIImage imageWithUIImage:chosenImage withLongEdgeAs:400];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma - Mark button events

// action for photo taking button
- (IBAction)takePhoto:(UIBarButtonItem *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
    self.cur_effective_width = -1;
    self.cur_effective_height = -1;
}

// action for photo selecting button
- (IBAction)selectPhoto:(UIBarButtonItem *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
    self.cur_effective_width = -1;
    self.cur_effective_height = -1;
}

- (IBAction)shrinkImage:(UIButton *)sender {
    
    self.view.userInteractionEnabled = NO;
    
    if (self.solver.currentWidth >= 0.1 * self.solver.width) {
        self.solver.currentWidth = self.solver.currentWidth - self.solver.width * 0.05;
    }
    
    [self.solver resizeToHeight:self.solver.height width:self.solver.currentWidth];
    
    //GradientOperator *operator = [[GradientOperator alloc] init];
    //self.imageView.image = [ImageHelper modifyImage:self.imageView.image withOperator:operator];
    self.imageView.image = self.solver.retargetedImage;
    
    self.view.userInteractionEnabled = YES;
}

- (IBAction)showSaliencyMap:(UIButton *)sender
{
    self.imageView.image = self.solver.saliencyImage;
}

- (IBAction)seamCarvingShrinkHorizonal:(UIButton *)sender {
    self.view.userInteractionEnabled = NO;
    if (self.cur_effective_width == -1) {
        self.cur_effective_width = self.imageView.image.size.width;
    }
    const int kC_width_to_reduce = 10;
    self.imageView.image = [ImageHelper modifyImageSeamCarvingShrinkHorizonal:self.imageView.image atWidth:self.cur_effective_width shrinkBy:kC_width_to_reduce];
    self.cur_effective_width -= kC_width_to_reduce;
    self.view.userInteractionEnabled = YES;
}

- (IBAction)seamCarvingShrinkVertical:(UIButton *)sender {
    self.view.userInteractionEnabled = NO;
    if (self.cur_effective_height == -1) {
        self.cur_effective_height = self.imageView.image.size.height;
    }
    const int kC_height_to_reduce = 10;
    self.imageView.image = [ImageHelper modifyImageSeamCarvingShrinkVertical:self.imageView.image atHeight:self.cur_effective_height shrinkBy:kC_height_to_reduce];
    self.cur_effective_height -= kC_height_to_reduce;
    self.view.userInteractionEnabled = YES;
}

// + (UIImage *)modifyImageSeamCarvingEnlargeVertical:(UIImage*)image atHeight:(int)cur_height enlargeBy: (int)added_height;
- (IBAction)seamCarvingEnlargeVertical:(UIButton *)sender {
    self.view.userInteractionEnabled = NO;
    if (self.cur_effective_height == -1) {
        self.cur_effective_height = self.imageView.image.size.height;
        self.originalImageForSeamCarvingEnlarge = self.imageView.image;
    }
    const int kC_height_to_add = 10;
    if (self.cur_effective_height + kC_height_to_add < 2 * self.originalImageForSeamCarvingEnlarge.size.height) {
        self.cur_effective_height += kC_height_to_add;
        self.imageView.image = [ImageHelper modifyImageSeamCarvingEnlargeVertical: self.originalImageForSeamCarvingEnlarge enlargeBy: (self.cur_effective_height - self.originalImageForSeamCarvingEnlarge.size.height)];
    }
    self.view.userInteractionEnabled = YES;
}

@end
