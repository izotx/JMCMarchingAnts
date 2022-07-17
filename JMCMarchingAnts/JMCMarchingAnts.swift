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

enum GeneralError: Error {
    case cgContextNotCreated
    case cgImageNotCreatedFromContext
    case cgImageNotAvailable
    case dataProviderNotCreated
}

extension CGRect {
    init(size: CGSize) {
        self.init(x: 0, y: 0, width: size.width, height: size.height)
    }
}

extension UIImage{
    public struct PixelData {
        var a:UInt8 = 255
        var r:UInt8
        var g:UInt8
        var b:UInt8
    }

    
            func fixedOrientation()->UIImage{
            UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
                self.draw(in: CGRect(size: self.size))
            
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return normalizedImage!
        }

    /** Helper function for saving image to png binary */
    func saveToPNG( filename:String) throws {
        let documentsPath:NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let destinationPath = documentsPath.appendingPathComponent(filename)
        try self.pngData()!.write(to: URL(fileURLWithPath: destinationPath))
        //UIImageJPEGRepresentation(image,1.0).writeToFile(destinationPath, atomically: true)
        
        
    }

    
    static func invertImageWithBlackBackground( foregroundImage:UIImage, frame:CGRect) throws -> UIImage{
    
        let realFrame = AVMakeRect(aspectRatio: foregroundImage.size, insideRect: frame)
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 1.0)
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            throw GeneralError.cgContextNotCreated
        }
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(size: frame.size))
        foregroundImage.draw(in: realFrame, blendMode:CGBlendMode.destinationOut, alpha: 1.0)
        if let cgimage = context.makeImage() {
            return UIImage(cgImage: cgimage)
            
        }
        throw GeneralError.cgImageNotCreatedFromContext
    }
    
    //Creates a ARGB Image
    func argbImage() throws -> UIImage
    {
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bytesPerRow = 4 * self.size.width
        guard let context = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            throw GeneralError.cgContextNotCreated
        }
        
        guard let cgImage = self.cgImage else {
            throw GeneralError.cgImageNotAvailable
        }
    
        context.draw(cgImage, in:CGRect(size: self.size))
        if let cgimage = context.makeImage() {
            return UIImage(cgImage: cgimage)
        }
        throw GeneralError.cgImageNotCreatedFromContext
    }
   
    //Image from raw bitmap
    internal func imageFromARGB32Bitmap(pixels:[PixelData], width:Int, height:Int) throws -> UIImage {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        
        assert(pixels.count == Int(width * height))
        let pixelDataSize = MemoryLayout<PixelData>.size
        
        var data = pixels // Copy to mutable []
        guard let providerRef = CGDataProvider(
            data: NSData(
                bytes: &data,
                length: data.count * pixelDataSize
            )
        ) else {
            throw GeneralError.dataProviderNotCreated
        }
        
        if let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * pixelDataSize,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent
            ) {
            return UIImage(cgImage: cgim)
        }
        throw GeneralError.cgImageNotCreatedFromContext
    }

    //Finds edges in the image (should be black and transparent colors only)
    func findEdges() throws -> UIImage {
        guard let cgImage:CGImage = try self.argbImage().cgImage else {
            throw GeneralError.cgImageNotAvailable
        }
        ////
        guard let dataProvider = cgImage.dataProvider else {
            throw GeneralError.dataProviderNotCreated
        }
        
        let pixelData = dataProvider.data
        
        //var data = CFDataGetMutableBytePtr
        let mdata: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let data = UnsafeMutablePointer<UInt8>(mutating:mdata)
        let height = cgImage.height
        let width = cgImage.width
        let start = CACurrentMediaTime()
        
        //create an empty buffer
        let emptyPixel = PixelData(a: 0, r: 0, g: 0, b: 0)
        let blackPixel = PixelData(a: 255, r: 255, g: 255, b: 255)
        
        var buffer = [PixelData](repeating: emptyPixel, count: Int(width  * height))
        var booleanArray = [Bool](repeating: false, count: Int(width  * height))
        
        //check vertically
        for y in 0 ..< height-1 {
            for x in 0 ..< width {
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
        
        
        for y in 0 ..< height-1 {
            for x in 0 ..< width-1 {
                
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
        
        
        let image = try imageFromARGB32Bitmap(pixels: buffer, width: width, height: height)
        
        print(stop - start)
        return image;
        
    }

    
}


//Main Class responsible for marching ants
class JMCMarchingAnts: NSObject {
    var visitedArray: [Bool]! //visited points
    var data: UnsafePointer<UInt8>! //pixel data
    
//Adds ants to the view's layer
    
    func addAnts(_ image:UIImage, imageView: UIView){
        try? addAnts(image: image, imageView: imageView)
    }
    
    func addAnts(image:UIImage, imageView: UIView) throws {
        let inverted =  try UIImage.invertImageWithBlackBackground(foregroundImage: image, frame: imageView.bounds)
        let edges = try inverted.findEdges();
        let selectionLayer = try self.getSelectionLayer(image: edges, imageView: imageView)
        imageView.layer.addSublayer(selectionLayer)
    }

    //Gets a layer with selected edges and adds animation
    func getSelectionLayer(image:UIImage, imageView: UIView) throws ->CAShapeLayer{
        let boundaryShapeLayer = CAShapeLayer()
        let path1  = try self.convertEdgesToPath(image: image.cgImage!)
//   let boundingBox = CGPathGetBoundingBox(path1)
//        UIGraphicsBeginImageContext(boundingBox.size)
//        let context  = UIGraphicsGetCurrentContext()
//        
//        CGContextAddPath(context, path1)
//        CGContextStrokePath(context)
//        
//        UIGraphicsEndImageContext()

     
        
        //get real position of the image
        let rect  =  AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        let  scaleFactor = rect.width/image.size.width

        var scaleTransform = CGAffineTransform.identity;
        scaleTransform = scaleTransform.scaledBy(x: scaleFactor, y: scaleFactor);
        
        //Customize the look of the edges here
        let scaledPath = path1.copy(using: &scaleTransform)
        boundaryShapeLayer.frame = rect
        boundaryShapeLayer.path = scaledPath
        boundaryShapeLayer.strokeColor = UIColor.white.cgColor
        boundaryShapeLayer.lineDashPattern = [5,5]
        boundaryShapeLayer.lineDashPhase = 1
        boundaryShapeLayer.fillColor = UIColor.clear.cgColor
        
        //starts animation
        let caanimation = self.addDashAnimation()
        
        boundaryShapeLayer.add(caanimation, forKey: "dash")
        return boundaryShapeLayer
        
    }
    
 //Converst Edges of the image to path
    func convertEdgesToPath(image:CGImage) throws ->CGMutablePath {
        guard let dataProvider = image.dataProvider else {
            throw GeneralError.dataProviderNotCreated
        }
        
        let pixelData = dataProvider.data

        
        data = CFDataGetBytePtr(pixelData)
        
        // data = UnsafeMutablePointer<UInt8>(mdata)
        let height = image.height
        let width = image.width
        _ = CACurrentMediaTime()
        
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        visitedArray = [Bool](repeating: false, count: Int(width  * height))
        
        //check vertically
        for y in 0 ..< height-1 {
            for x in 0 ..< width {
                
                //Current one
                let currentPixelInfo: Int = ((Int(width) * Int(y)) + Int(x)) * 4
                let currentAlpha = CGFloat(data[currentPixelInfo+3]) / CGFloat(255.0)
                
                
                let downPixelInfo: Int = ((Int(width) * Int(y+1)) + Int(x)) * 4
                _ = CGFloat(data[downPixelInfo+3]) / CGFloat(255.0)
                var currentPoint = CGPoint(x: CGFloat(x), y: CGFloat(y))
                // print(currentPoint)
                
                if visitedArray[currentPixelInfo/4] == true {//if we didn't already check this point
                    continue
                }
                visitedArray[currentPixelInfo/4] = true //mark as visited
                
                if currentAlpha == 0{ //We didn't detect the edge so we can move on to the next point
                    continue
                    
                }
                
                var adjacent = true
                path.move(to: currentPoint)
                
                while (adjacent){
                    
                    // print(currentPoint)
                    var neighbor: CGPointNeighbor? = nil
                    
                    if checkTopLeft(currentPoint, data: data, width: width, height: height)
                    {
                        neighbor = .upperLeft
                    }
                    else if checkLeft(currentPoint, data: data, width: width, height: height){
                        neighbor = .left
                    }
                    else if checkBottomLeft(currentPoint, data: data, width: width, height: height){
                        neighbor = .lowerLeft
                    }
                    else if checkBottom(currentPoint, data: data, width: width, height: height){
                        neighbor = .lower
                    }
                    else if checkBottomRight(currentPoint, data: data, width: width, height: height){
                        neighbor = .lowerRight
                    }
                    else if checkRight(currentPoint, data: data, width: width, height: height){
                        neighbor = .right
                    }
                    else if checkTopRight(currentPoint, data: data, width: width, height: height){
                        neighbor = .upperRight
                    }
                    else if checkTop(currentPoint, data: data, width: width, height: height){
                        neighbor = .upper
                    }
                    else{
                        adjacent = false
                    }

                    if let neighbor = neighbor {
                        let adjacentPoint = currentPoint.adjacent(neighbor)
                        path.addLine(to: adjacentPoint)
                        currentPoint = adjacentPoint
                    }

                }
            }
        }
        return path
    }
    
    //Checking top right point
    func checkTopRight(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if Int(point.y) == 0 || Int(point.x) == width-1 //edge case
        {
            return false
        }
        
        let index = ((Int(width) * Int(point.y-1)) + Int(point.x+1)) * 4
        return checkPoint(index: index)
    }
    
    //Checking right point
    func checkRight(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if  Int(point.y) == 0 || Int(point.x) == width-1 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y)) + Int(point.x+1)) * 4
        return checkPoint(index: index)
    }
    
    //Checking bottom right point
    func checkBottomRight(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if Int(point.y) == height-1 || Int(point.x) == width-1 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y+1)) + Int(point.x+1)) * 4
        return checkPoint(index: index)
    }
    
    
    //Checking bottom
    func checkBottom(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if  Int(point.y) == height-1 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y+1)) + Int(point.x)) * 4
        return checkPoint(index: index)
    }
    
    //Checking bottom left
    func checkBottomLeft(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if  Int(point.y) == height-1 || Int(point.x) == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y+1)) + Int(point.x-1)) * 4
        return checkPoint(index: index)
    }
    
    //Checking  left
    func checkLeft(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if point.x == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y)) + Int(point.x-1)) * 4
        return checkPoint(index: index)
    }
    
    //Checking  Top left
    func checkTopLeft(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if Int(point.x) == 0 || Int(point.y) == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y-1)) + Int(point.x-1)) * 4
        return checkPoint(index: index)
    }
    
    //Checking Top
    func checkTop(_ point:CGPoint, data:UnsafePointer<UInt8>, width:Int, height:Int )->Bool{
        if   Int(point.y) == 0 //edge case
        {
            return false
        }
        let index = ((Int(width) * Int(point.y-1)) + Int(point.x)) * 4
        return checkPoint(index: index)
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
