//
//  JMCMarchingAnts.swift
//  JMCImageProcesssing
//
//  Created by Janusz Chudzynski on 7/26/15.
//  Copyright (c) 2015 Izotx. All rights reserved.


/**
This file is part of JMCMarchingAnts.
    
JMCMarchingAnts is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

JMCMarchingAnts is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
along with JMCMarchingAnts.  If not, see <http://www.gnu.org/licenses/>.
*/

import UIKit
import AVFoundation



extension UIImage{
    public struct PixelData {
        var a:UInt8 = 255
        var r:UInt8
        var g:UInt8
        var b:UInt8
    }

    
            func fixedOrientation()->UIImage{
            UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
            self.drawInRect(CGRectMake(0, 0, self.size.width,self.size.height))
            
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return normalizedImage;
        }

    /** Helper function for saving image to png binary */
    func saveToPNG( filename:String){
        let documentsPath:NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let destinationPath = documentsPath.stringByAppendingPathComponent(filename)
        UIImagePNGRepresentation(self)!.writeToFile(destinationPath, atomically: true)
        //UIImageJPEGRepresentation(image,1.0).writeToFile(destinationPath, atomically: true)
        
        
    }

    
    static func invertImageWithBlackBackground( foregroundImage:UIImage, frame:CGRect)->UIImage{
    
        let realFrame =  AVMakeRectWithAspectRatioInsideRect(foregroundImage.size, frame)
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 1.0)
        let context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextFillRect(context, CGRectMake(0,0,frame.size.width,frame.size.height))
    foregroundImage.drawInRect(CGRectMake(realFrame.origin.x,realFrame.origin.y,realFrame.size.width,realFrame.size.height), blendMode:CGBlendMode.DestinationOut, alpha: 1.0)
        let cgimage =  CGBitmapContextCreateImage(context);
        let image = UIImage(CGImage: cgimage!)
        UIGraphicsEndImageContext();
        return image;
    }
    
    //Creates a ARGB Image
    func argbImage()->UIImage?
    {
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()!
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bytesPerRow = 4 * self.size.width
        let context = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), 8, Int(bytesPerRow), colorSpace, bitmapInfo.rawValue)
    
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(self.size.width), CGFloat(self.size.height)), self.CGImage)
        let cgimage = CGBitmapContextCreateImage(context)
        let img = UIImage(CGImage: cgimage!)
        return img
    }
   
    //Image from raw bitmap
    internal func imageFromARGB32Bitmap(pixels:[PixelData], width:Int, height:Int)->UIImage? {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        
        assert(pixels.count == Int(width * height))
        
        var data = pixels // Copy to mutable []
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &data, length: data.count * sizeof(PixelData))
        )
        
        
        let cgim = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            width * Int(sizeof(PixelData)),
            rgbColorSpace,
            bitmapInfo,
            providerRef,
            nil,
            true,
            CGColorRenderingIntent.RenderingIntentDefault
        )
        return UIImage(CGImage: cgim!)
    }

    //Finds edges in the image (should be black and transparent colors only)
    func findEdges()->UIImage{
        let cgImage:CGImageRef = self.argbImage()!.CGImage!
        ////
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage))
        
        
        //var data = CFDataGetMutableBytePtr
        let mdata: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let data = UnsafeMutablePointer<UInt8>(mdata)
        let height = CGImageGetHeight(cgImage)
        let width = CGImageGetWidth(cgImage)
        let start = CACurrentMediaTime()
        
        //create an empty buffer
        let emptyPixel = PixelData(a: 0, r: 0, g: 0, b: 0)
        let blackPixel = PixelData(a: 255, r: 255, g: 255, b: 255)
        
        var buffer = [PixelData](count: Int(width  * height), repeatedValue: emptyPixel)
        var booleanArray = [Bool](count: Int(width  * height), repeatedValue: false)
        
        //check vertically
        for var y = 0; y < height-1; y++ {
            for var x = 0; x < width; x++ {
                //Current one
                let currentPixelInfo: Int = ((Int(width) * Int(y)) + Int(x)) * 4
                let currentAlpha = CGFloat(data[currentPixelInfo+0]) / CGFloat(255.0)
                let downPixelInfo: Int = ((Int(width) * Int(y+1)) + Int(x)) * 4
                let downAlpha = CGFloat(data[downPixelInfo+0]) / CGFloat(255.0)
                
                if y == 0 && currentAlpha != 0{ // Top Edge
                    booleanArray[currentPixelInfo/4] = true
                    buffer[currentPixelInfo/4] = blackPixel
                }
                
                if y > 0 && y < height - 2{
                    //one up
                    let topPixelInfo: Int = ((Int(width) * Int(y - 1)) + Int(x )) * 4
                    let topAlpha = CGFloat(data[topPixelInfo]) / CGFloat(255.0)
                    
                    if downAlpha == 0 && currentAlpha != 0 {//edge
                        booleanArray[currentPixelInfo/4] = true
                        buffer[currentPixelInfo/4] = blackPixel
                    }
                    
                    if topAlpha == 0 && currentAlpha != 0 {//edge
                        booleanArray[currentPixelInfo/4] = true
                        buffer[currentPixelInfo/4] = blackPixel
                    }
                    
                }
                
                if y == height - 2 && downAlpha != 0 {
                    booleanArray[downPixelInfo/4] = true
                    buffer[downPixelInfo/4] = blackPixel
                }
                
            }
        }
        
        
        for var y = 0; y < height-1; y++ {
            for var x = 0; x < width-1; x++ {
                
                //Current one
                let currentPixelInfo: Int = ((Int(width) * Int(y)) + Int(x)) * 4
                let currentAlpha = CGFloat(data[currentPixelInfo]) / CGFloat(255.0)
                //Next
                let nextPixelInfo: Int = ((Int(width) * Int(y)) + Int(x + 1)) * 4
                let nextAlpha = CGFloat(data[nextPixelInfo]) / CGFloat(255.0)
                
                
                //check horizontally
                if x == 0 && currentAlpha != 0{ // Edge case
                    booleanArray[currentPixelInfo/4] = true
                    buffer[currentPixelInfo/4] = blackPixel
                }
                if x > 0 && x < width - 2{
                    //One before
                    let previousPixelInfo: Int = ((Int(width) * Int(y)) + Int(x - 1)) * 4
                    let previousAlpha = CGFloat(data[previousPixelInfo]) / CGFloat(255.0)
                    
                    if nextAlpha == 0 && currentAlpha != 0 {//Living on the edge
                        booleanArray[currentPixelInfo/4] = true
                        buffer[currentPixelInfo/4] = blackPixel
                    }
                    if previousAlpha == 0 && currentAlpha != 0 {//Living on the edge
                        booleanArray[currentPixelInfo/4] = true
                        buffer[currentPixelInfo/4] = blackPixel
                    }
                }
                
                if x == width - 2 && nextAlpha != 0 {
                    booleanArray[nextPixelInfo/4] = true
                    buffer[nextPixelInfo/4] = blackPixel
                }
            }
        }
        
        
        let stop = CACurrentMediaTime()
        
        
        let image = imageFromARGB32Bitmap(buffer, width: width, height: height)
        
        print(stop - start)
        return image!;
        
    }

    
}


//Main Class responsible for marching ants
class JMCMarchingAnts: NSObject {
    var visitedArray: [Bool]! //visited points
    var data: UnsafePointer<UInt8>! //pixel data
    
//Adds ants to the view's layer
    func addAnts(image:UIImage, imageView: UIView){
        let inverted =  UIImage.invertImageWithBlackBackground(image, frame: imageView.bounds)
        let edges = inverted.findEdges();
        let selectionLayer = self.getSelectionLayer(edges, imageView: imageView)
        imageView.layer.addSublayer(selectionLayer)
    }

    //Gets a layer with selected edges and adds animation
    func getSelectionLayer(image:UIImage, imageView: UIView)->CAShapeLayer{
        let boundaryShapeLayer = CAShapeLayer()
        let path1  = self.convertEdgesToPath(image.CGImage!)
//   let boundingBox = CGPathGetBoundingBox(path1)
//        UIGraphicsBeginImageContext(boundingBox.size)
//        let context  = UIGraphicsGetCurrentContext()
//        
//        CGContextAddPath(context, path1)
//        CGContextStrokePath(context)
//        
//        UIGraphicsEndImageContext()

     
        
        //get real position of the image
        let rect  =  AVMakeRectWithAspectRatioInsideRect(image.size, imageView.bounds)
        let  scaleFactor = CGRectGetWidth(rect)/image.size.width

        var scaleTransform = CGAffineTransformIdentity;
        scaleTransform = CGAffineTransformScale(scaleTransform, scaleFactor, scaleFactor);
        
        //Customize the look of the edges here
        let scaledPath = CGPathCreateCopyByTransformingPath(path1, &scaleTransform)
        boundaryShapeLayer.frame = rect
        boundaryShapeLayer.path = scaledPath
        boundaryShapeLayer.strokeColor = UIColor.whiteColor().CGColor
        boundaryShapeLayer.lineDashPattern = [5,5]
        boundaryShapeLayer.lineDashPhase = 1
        boundaryShapeLayer.fillColor = UIColor.clearColor().CGColor
        
        //starts animation
        let caanimation = self.addDashAnimation()
        
        boundaryShapeLayer.addAnimation(caanimation, forKey: "dash")
        return boundaryShapeLayer
        
    }
    
 //Converst Edges of the image to path
    func convertEdgesToPath(image:CGImageRef)->CGMutablePathRef{
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image))
        
        data = CFDataGetBytePtr(pixelData)
        
        // data = UnsafeMutablePointer<UInt8>(mdata)
        let height = CGImageGetHeight(image)
        let width = CGImageGetWidth(image)
        _ = CACurrentMediaTime()
        
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, CGRectMake(0, 0, CGFloat(width), CGFloat(height)))

        visitedArray = [Bool](count: Int(width  * height), repeatedValue: false)
        
        //check vertically
        for var y = 0; y < height-1; y++ {
            for var x = 0; x < width; x++ {
                
                //Current one
                let currentPixelInfo: Int = ((Int(width) * Int(y)) + Int(x)) * 4
                let currentAlpha = CGFloat(data[currentPixelInfo+3]) / CGFloat(255.0)
                
                
                let downPixelInfo: Int = ((Int(width) * Int(y+1)) + Int(x)) * 4
                _ = CGFloat(data[downPixelInfo+3]) / CGFloat(255.0)
                var currentPoint = CGPointMake(CGFloat(x ), CGFloat(y))
                // print(currentPoint)
                
                if visitedArray[currentPixelInfo/4] == true {//if we didn't already check this point
                    continue
                }
                visitedArray[currentPixelInfo/4] = true //mark as visited
                
                if currentAlpha == 0{ //We didn't detect the edge so we can move on to the next point
                    continue
                    
                }
                
                var adjacent = true
                CGPathMoveToPoint(path, nil, CGFloat(x), CGFloat(y))
                
                while (adjacent){
                    
                    // print(currentPoint)
                    
                    if checkTopLeft(currentPoint, data: data, width: width, height: height)
                    {
                        
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x-1), CGFloat(currentPoint.y-1))
                        
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                    }
                    else if checkLeft(currentPoint, data: data, width: width, height: height){
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x-1), CGFloat(currentPoint.y))
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                        
                        
                    }
                    else if checkBottomLeft(currentPoint, data: data, width: width, height: height){
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x-1), CGFloat(currentPoint.y+1))
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                        
                    }
                    else if checkBottom(currentPoint, data: data, width: width, height: height){
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x), CGFloat(currentPoint.y+1))
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                        
                    }
                    else if checkBottomRight(currentPoint, data: data, width: width, height: height){
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x+1), CGFloat(currentPoint.y+1))
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                        
                        
                    }
                    else if checkRight(currentPoint, data: data, width: width, height: height){
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x+1), CGFloat(currentPoint.y))
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                        
                        
                    }
                    else if checkTopRight(currentPoint, data: data, width: width, height: height){
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x+1), CGFloat(currentPoint.y-1))
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                        
                        
                    }
                    else if checkTop(currentPoint, data: data, width: width, height: height){
                        let tempPoint = CGPointMake(CGFloat(currentPoint.x), CGFloat(currentPoint.y-1))
                        CGPathAddLineToPoint(path, nil, tempPoint.x, tempPoint.y)
                        currentPoint = tempPoint
                        
                        
                    }
                    else{
                        adjacent = false
                    }
                }
            }
        }
        return path
    }
    
    //Checking top right point
    func checkTopRight(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if Int(point.y) == 0 || Int(point.x) == width-1 //edge case
        {
            return false
        }
        
        let index = ((Int(width) * Int(point.y-1)) + Int(point.x+1)) * 4
        return checkPoint(index)
    }
    
    //Checking right point
    func checkRight(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if  Int(point.y) == 0 || Int(point.x) == width-1 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y)) + Int(point.x+1)) * 4
        return checkPoint(index)
    }
    
    //Checking bottom right point
    func checkBottomRight(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if Int(point.y) == height-1 || Int(point.x) == width-1 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y+1)) + Int(point.x+1)) * 4
        return checkPoint(index)
    }
    
    
    //Checking bottom
    func checkBottom(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if  Int(point.y) == height-1 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y+1)) + Int(point.x)) * 4
        return checkPoint(index)
    }
    
    //Checking bottom left
    func checkBottomLeft(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if  Int(point.y) == height-1 || Int(point.x) == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y+1)) + Int(point.x-1)) * 4
        return checkPoint(index)
    }
    
    //Checking  left
    func checkLeft(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if point.x == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y)) + Int(point.x-1)) * 4
        return checkPoint(index)
    }
    
    //Checking  Top left
    func checkTopLeft(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if Int(point.x) == 0 || Int(point.y) == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y-1)) + Int(point.x-1)) * 4
        return checkPoint(index)
    }
    
    //Checking Top
    func checkTop(point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if   Int(point.y) == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y-1)) + Int(point.x)) * 4
        return checkPoint(index)
    }
    
    
    func checkPoint(index:Int )->Bool{
        
        //check if it is visible
        let currentAlpha = CGFloat(data[index+3]) / CGFloat(255.0)
        
        if visitedArray[index/4] == true{ //check if visited
            return false
        }
        
        visitedArray[index/4] = true //mark as visited
        
        if currentAlpha != 0{
            return true;
        }
        return false
    }
   
    
    func addDashAnimation()->CAAnimation{
        let animation = CABasicAnimation(keyPath: "lineDashPhase")
        animation.duration = 0.75
        animation.fromValue =  0
        animation.toValue = 10
        animation.repeatCount = HUGE
        animation.autoreverses = false
        return animation
    }
}
