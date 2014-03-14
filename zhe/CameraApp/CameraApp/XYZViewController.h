//
//  XYZViewController.h
//  CameraApp
//
//  Created by zhe-mac on 14-3-13.
//  Copyright (c) 2014年 zhe-mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)selectPhoto:(UIButton *)sender;
- (IBAction)modifyImage:(UIButton *)sender;

@end
