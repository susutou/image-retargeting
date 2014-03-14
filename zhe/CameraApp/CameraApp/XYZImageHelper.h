//
//  XYZImageHelper.h
//  CameraApp
//
//  Created by zhe-mac on 14-3-13.
//  Copyright (c) 2014年 zhe-mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYZImageHelper : NSObject
+ (unsigned char *)getRGBAsFromImage:(UIImage *)image atX:(int)xx andY:(int)yy count:(int)count;

@end
