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
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    self.imageView.image = [UIImage imageWithUIImage:chosenImage withLongEdgeAs:400];
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

- (void)shrinkImageHorizontallyQP
{
    
    self.view.userInteractionEnabled = NO;
    
    if (self.solver.currentWidth >= 0.1 * self.solver.width) {
        self.solver.currentWidth = self.solver.currentWidth - self.solver.width * 0.05;
    }
    
    [self.solver resizeToHeight:self.solver.currentHeight width:self.solver.currentWidth];
    
    self.imageView.image = self.solver.retargetedImage;
    
    self.view.userInteractionEnabled = YES;
}

- (void)shrinkImageVerticallyQP
{
    self.view.userInteractionEnabled = NO;
    
    if (self.solver.currentHeight >= 0.1 * self.solver.height) {
        self.solver.currentHeight = self.solver.currentHeight - self.solver.height * 0.05;
    }
    
    [self.solver resizeToHeight:self.solver.currentHeight width:self.solver.currentWidth];
    
    self.imageView.image = self.solver.retargetedImage;
    
    self.view.userInteractionEnabled = YES;
}

- (void)growImageHorizontallyQP
{
    self.view.userInteractionEnabled = NO;
    
    if (self.solver.currentWidth < 2 * self.solver.width) {
        self.solver.currentWidth = self.solver.currentWidth + self.solver.width * 0.05;
    }
    
    [self.solver resizeToHeight:self.solver.currentHeight width:self.solver.currentWidth];
    
    self.imageView.image = self.solver.retargetedImage;
    
    self.view.userInteractionEnabled = YES;
}

- (void)growImageVerticallyQP
{
    self.view.userInteractionEnabled = NO;
    
    if (self.solver.currentHeight < 2 * self.solver.height) {
        self.solver.currentHeight = self.solver.currentHeight + self.solver.height * 0.05;
    }
    
    [self.solver resizeToHeight:self.solver.currentHeight width:self.solver.currentWidth];
    
    self.imageView.image = self.solver.retargetedImage;
    
    self.view.userInteractionEnabled = YES;
}

- (IBAction)showSaliencyMap:(UIButton *)sender
{
    self.imageView.image = self.solver.saliencyImage;
}

- (void)seamCarvingShrinkHorizonal
{
    self.view.userInteractionEnabled = NO;
    if (self.cur_effective_width == -1) {
        self.cur_effective_width = self.imageView.image.size.width;
    }
    const int kC_width_to_reduce = 10;
    self.imageView.image = [ImageHelper modifyImageSeamCarvingShrinkHorizonal:self.imageView.image atWidth:self.cur_effective_width shrinkBy:kC_width_to_reduce];
    self.cur_effective_width -= kC_width_to_reduce;
    self.view.userInteractionEnabled = YES;
}

- (void)seamCarvingShrinkVertical
{
    self.view.userInteractionEnabled = NO;
    if (self.cur_effective_height == -1) {
        self.cur_effective_height = self.imageView.image.size.height;
    }
    const int kC_height_to_reduce = 10;
    self.imageView.image = [ImageHelper modifyImageSeamCarvingShrinkVertical:self.imageView.image atHeight:self.cur_effective_height shrinkBy:kC_height_to_reduce];
    self.cur_effective_height -= kC_height_to_reduce;
    self.view.userInteractionEnabled = YES;
}

- (void)seamCarvingEnlargeVertical
{
    self.view.userInteractionEnabled = NO;
    if (self.cur_effective_height < self.solver.originalImage.size.height) {
        self.imageView.image = self.solver.originalImage;
        self.cur_effective_height = self.imageView.image.size.height;
        self.originalImageForSeamCarvingEnlarge = self.imageView.image;
    }
    const int kC_height_to_add = 10;
    if (self.cur_effective_height + kC_height_to_add < 2 * self.originalImageForSeamCarvingEnlarge.size.height) {
        self.cur_effective_height += kC_height_to_add;
        self.imageView.image = [ImageHelper modifyImageSeamCarvingEnlargeVertical: self.originalImageForSeamCarvingEnlarge enlargeBy: (self.cur_effective_height - self.originalImageForSeamCarvingEnlarge.size.height)];
    }
    self.cur_effective_width = -1;
    self.view.userInteractionEnabled = YES;
}

// general actions
- (IBAction)shrinkImageHorizontally:(UIBarButtonItem *)sender
{
    if ([[self modeControl] selectedSegmentIndex] == 0) {
        // seam carving
        [self seamCarvingShrinkHorizonal];
    } else {
        // segmented-based retargeting
        [self shrinkImageHorizontallyQP];
    }
}

- (IBAction)shrinkImageVertically:(UIBarButtonItem *)sender
{
    if ([[self modeControl] selectedSegmentIndex] == 0) {
        // seam carving
        [self seamCarvingShrinkVertical];
    } else {
        // segmented-based retargeting
        [self shrinkImageVerticallyQP];
    }
}

- (IBAction)growImageHorizontally:(UIBarButtonItem *)sender
{
    if ([[self modeControl] selectedSegmentIndex] == 0) {
        // seam carving
        // no compatible operations
    } else {
        // segmented-based retargeting
        [self growImageHorizontallyQP];
    }
}

- (IBAction)growImageVertically:(UIBarButtonItem *)sender
{
    if ([[self modeControl] selectedSegmentIndex] == 0) {
        // seam carving
        [self seamCarvingEnlargeVertical];
    } else {
        // segmented-based retargeting
        [self growImageVerticallyQP];
    }
}

- (IBAction)savePicture:(UIBarButtonItem *)sender
{
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
    UIImageWriteToSavedPhotosAlbum([[self imageView] image], nil, nil, nil);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image saved!"
                                                    message:@"The image is saved successfully!"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
- (IBAction)changeMode:(UISegmentedControl *)sender {
    self.imageView.image = self.solver.originalImage;
    self.cur_effective_height = -1;
    self.cur_effective_width = -1;
}

@end
