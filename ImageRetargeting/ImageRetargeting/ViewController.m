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
    RetargetingSolver *solver = [[RetargetingSolver alloc] initWithImage:chosenImage];
    
    self.imageView.image = solver.saliencyImage;
    
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
    
    //GradientOperator *operator = [[GradientOperator alloc] init];
    //self.imageView.image = [ImageHelper modifyImage:self.imageView.image withOperator:operator];
    
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
