//
//  GradientOperator.m
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/15/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import "GradientOperator.h"

@implementation GradientOperator

- (void)changeImage:(CGImageRef)imageRef withData:(unsigned char *)data
{
    // NSLog(@"GradientOperator");
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    for (int i = 0; i < width * height; i += 1) {
        data[i * 4] = self.gradient[i];
        data[i * 4 + 1] = self.gradient[i];
        data[i * 4 + 2] = self.gradient[i];
    }
    // 0.2989, 0.5870, 0.1140
}

@end
