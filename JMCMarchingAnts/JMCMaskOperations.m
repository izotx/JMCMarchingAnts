//
//  JMCMaskOperations.m
//  JMCImageProcesssing
//
//  Created by Janusz Chudzynski on 7/22/15.
//  Copyright (c) 2015 Izotx. All rights reserved.
//

#import "JMCMaskOperations.h"


@implementation JMCMaskOperations

+(UIImage *)composeImageWithForeground:(UIImage *)foregroundImage{
    CGSize size = foregroundImage.size;
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //    [backgroundImage drawInRect:CGRectMake(0,0,size.width,size.height) ];
    CGContextSetFillColorWithColor(context, [[UIColor blackColor]CGColor]); //(CONT, <#const CGFloat *components#>)
    CGContextFillRect(context, CGRectMake(0,0,size.width,size.height));
    [foregroundImage drawInRect:CGRectMake(0,0,size.width,size.height) blendMode:kCGBlendModeDestinationOut alpha:1.0];
    CGImageRef cgimage =  CGBitmapContextCreateImage(context);
    UIImage * image = [UIImage imageWithCGImage:cgimage];
    UIGraphicsEndImageContext();
    
    return image;
    
}

+(UIImage *)composeImageWithBackground: (UIImage *) background andForeground:(UIImage *)foregroundImage{
    CGSize size = foregroundImage.size;
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //    [backgroundImage drawInRect:CGRectMake(0,0,size.width,size.height) ];
    CGContextSetFillColorWithColor(context, [[UIColor blackColor]CGColor]); //(CONT, <#const CGFloat *components#>)
    CGContextFillRect(context, CGRectMake(0,0,size.width,size.height));
    [foregroundImage drawInRect:CGRectMake(0,0,size.width,size.height) blendMode:kCGBlendModeDestinationOut alpha:1.0];
    CGImageRef cgimage =  CGBitmapContextCreateImage(context);
    UIImage * image = [UIImage imageWithCGImage:cgimage];
    UIGraphicsEndImageContext();
    
    return image;
    
}



+(CALayer*)createImageMaskWithFrame:(CGRect)frame{
    UIImage * mask =  [self composeImageWithForeground:[UIImage imageNamed:@"mask"]];
    
    CAShapeLayer* maskLayer = [CAShapeLayer layer];
    maskLayer.frame = frame;
    maskLayer.contents = (__bridge id)([mask CGImage]);
    maskLayer.borderColor = [[UIColor whiteColor]CGColor];
    maskLayer.borderWidth = 1.0;
    
    CALayer * compositeMaskLayer = [CALayer layer];
    compositeMaskLayer.frame = frame;
    compositeMaskLayer.masksToBounds = YES;
    [compositeMaskLayer setMask:maskLayer];
    compositeMaskLayer.borderColor = [[UIColor whiteColor]CGColor];
    compositeMaskLayer.borderWidth = 1.0;
    
    CALayer *translucentLayer = [CALayer layer];
    translucentLayer.frame =  frame ;
    [translucentLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [translucentLayer setOpacity:0.7];
    
    [compositeMaskLayer addSublayer:translucentLayer];
    return  compositeMaskLayer;
}
@end
