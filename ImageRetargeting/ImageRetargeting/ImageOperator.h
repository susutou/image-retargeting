//
//  ImageOperator.h
//  ImageRetargeting
//
//  Created by Susen Zhao on 3/15/14.
//  Copyright (c) 2014 Susen Zhao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageOperator : NSObject

- (void)changeImage:(CGImageRef)imageRef withData:(unsigned char *)data;

@end
