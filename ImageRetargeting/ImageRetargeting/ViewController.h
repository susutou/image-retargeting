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
@property (strong, nonatomic) RetargetingSolver *solver;

- (IBAction)takePhoto:(UIBarButtonItem *)sender;
- (IBAction)selectPhoto:(UIBarButtonItem *)sender;
- (IBAction)shrinkImage:(UIButton *)sender;
- (IBAction)showSaliencyMap:(UIButton *)sender;

- (IBAction)seamCarvingShrinkHorizonal:(UIButton *)sender;
- (IBAction)seamCarvingShrinkVertical:(UIButton *)sender;
- (IBAction)seamCarvingEnlargeVertical:(UIButton *)sender;
@end
