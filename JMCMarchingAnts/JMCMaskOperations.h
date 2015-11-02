//
//  JMCMaskOperations.h
//  JMCImageProcesssing
//
//  Created by Janusz Chudzynski on 7/22/15.
//  Copyright (c) 2015 Izotx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface JMCMaskOperations : NSObject
+(CALayer*)createImageMaskWithFrame:(CGRect)frame;
+(UIImage *)composeImageWithForeground:(UIImage *)foregroundImage;
+(UIImage *)composeImageWithBackground: (UIImage *) background andForeground:(UIImage *)foregroundImage;
    

@end
