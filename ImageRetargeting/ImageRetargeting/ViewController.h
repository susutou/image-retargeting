//
//  ViewController.h
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/13/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageHelper.h"
#import "RetargetingSolver.h"
#import "UIImage+Resize.h"
#import "GradientOperator.h"

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)selectPhoto:(UIButton *)sender;
- (IBAction)shrinkImage:(UIButton *)sender;

@end
