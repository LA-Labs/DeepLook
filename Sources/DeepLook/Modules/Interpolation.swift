//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import simd
import Accelerate
import Vision
#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif
class Interpolation {
    
    static func extractImageChip(_ image: UIImage,
                                 chipDetail: ChipDetails,
                                 observation: VNFaceObservation,
                                 processConfiguration: ProcessConfiguration) -> (image: UIImage?, roll: Double) {
        guard let image = rotate(image: image,
                                 chipDetail: chipDetail,
                                 observation: observation,
                                 processConfiguration: processConfiguration) else {
            return (nil, 0)
        }
        guard let croppedImage = crop(image: image,
                                      rect: CGRect(origin: chipDetail.rect.topLeft.toPoint(),
                                                   size: chipDetail.rect.size)) else {
            return (nil, 0)
        }
        let scaledImage = scale(image: croppedImage,
                                targetSize: CGSize(width: processConfiguration.faceChipSize,
                                                   height: processConfiguration.faceChipSize))
        return (scaledImage, chipDetail.roll)
    }
    
    static func getFaceChipDetails(det: VNFaceObservation,
                                   imageSize: CGSize,
                                   size: Double = 160,
                                   padding: Double = 0.0,
                                   processConfiguration: ProcessConfiguration) -> ChipDetails {
        var featurePointsVectors: [simd_double2] = []
        
        switch processConfiguration.landmarksAlignmentAlgorithm {
        case .pointsDlib32:
            featurePointsVectors = det.facePointsVectors76(in: imageSize)
        case .pointsDlib5:
            featurePointsVectors = det.facePointsVectorsDlib5(in: imageSize)
        case .pointsSphereFace5:
            featurePointsVectors = det.facePointsVectorsSphereFace5(in: imageSize)
        }
        return getChipDetails(toPoints: featurePointsVectors,
                              size: CGSize(width: size, height: size), padding: padding,
                              featurePointsAlgorithm: processConfiguration.landmarksAlignmentAlgorithm)
    }
    
    struct ChipDetails {
        let rect: Rectangle
        let roll: Double
        let rows: Double
        let cols: Double
        let scale: Double
        
        init(fromPoint: [simd_double2],
             toPoint: [simd_double2],
             chipDims: simd_double2)
        {
            rows = Double(chipDims.x)
            cols = Double(chipDims.y)
            let tform = similarityTransform(fromPoint: fromPoint, toPoint: toPoint)!
            let p = tform.m * simd_double2(1, 0)
            roll = atan2(p.y, p.x)
            scale = p.length
            
            rect = CenteredDrect(point: tform.applyTransform(simd_double2(chipDims.x, chipDims.y)/2),
                                 width: chipDims.x * (scale), height: chipDims.y * (scale))
        }
    }
    
}
private extension Interpolation {
    
    static func crop(image: UIImage, rect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: rect.size.width,
                                                      height: rect.size.height ), true, 0.0)
        image.draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage
    }
    
    static func rotate(image: UIImage,
                   chipDetail: ChipDetails,
                   observation: VNFaceObservation,
                   processConfiguration: ProcessConfiguration) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: CGFloat(chipDetail.rect.left) + CGFloat(chipDetail.rect.width/2),
                             y: CGFloat(chipDetail.rect.top) + CGFloat(chipDetail.rect.width/2))
        context?.rotate(by: CGFloat(-chipDetail.roll))
        context?.translateBy(x: -(CGFloat(chipDetail.rect.left) + CGFloat(chipDetail.rect.width/2)),
                             y: -(CGFloat(chipDetail.rect.top) + CGFloat(chipDetail.rect.width/2)))
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        context?.saveGState()
        context?.setStrokeColor(UIColor.red.cgColor)

        if processConfiguration.drawFeaturePoints {
            
            
            
            var points: [simd_double2]
            
            switch processConfiguration.landmarksAlignmentAlgorithm {
            case .pointsDlib32:
                points = observation.facePointsVectors76(in: image.size)
            case .pointsDlib5:
                points = observation.facePointsVectorsDlib5(in: image.size)
            case .pointsSphereFace5:
                points = observation.facePointsVectorsSphereFace5(in: image.size)
            }
            
            points
                .map({$0.toPoint()})
                .forEach { (point) in
                    context?.addArc(center: point, radius: 1,
                                    startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
                    context?.strokePath()
                    context?.saveGState()
                }
        }
        
        // get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()

        // end drawing context
        UIGraphicsEndImageContext()

        return finalImage
    }
    
    static func scale(image: UIImage, targetSize: CGSize) -> UIImage? {
       let size = image.size

       let widthRatio  = targetSize.width  / size.width
       let heightRatio = targetSize.height / size.height

       // Figure out what our orientation is, and use that to form the rectangle
       var newSize: CGSize
       if(widthRatio > heightRatio) {
           newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
       } else {
           newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
       }

       // This is the rect that we've calculated out and this is what is actually used below
       let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

       // Actually do the resizing to the rect using the ImageContext stuff
       UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
       image.draw(in: rect)
       let newImage = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()

       return newImage
   }
    
    static func getChipDetails(toPoints: [simd_double2], size: CGSize, padding: Double, featurePointsAlgorithm: ProcessConfiguration.LandmarksAlignmentAlgorithm) -> ChipDetails {

        var points: [simd_double2]
        switch featurePointsAlgorithm {
        case .pointsDlib32:
            points = getFaceParts68(size: simd_double2(Double(size.width), Double(size.height)), padding: padding)
        case .pointsDlib5:
            points = getFacePartsDlib5(size: simd_double2(Double(size.width), Double(size.height)), padding: padding)
        case .pointsSphereFace5:
            points = getFacePartsSphereFace5(size: simd_double2(Double(size.width), Double(size.height)), padding: padding)
        }

        let chipDetail = ChipDetails(fromPoint: points,
                                                toPoint: toPoints,
                                                chipDims: simd_double2(Double(size.width), Double(size.height)))
        return chipDetail
    }
    
    static func similarityTransform(fromPoint: [simd_double2], toPoint: [simd_double2]) -> PointTransformAffine?  {
        precondition(fromPoint.count == toPoint.count)
        let A = fromPoint.map(pointToMetrix).flatMap({$0})
        let B = toPoint.map(pointToVector).flatMap({$0})
        guard let tform = LinearAlgebra.solveLeastSquare(A: A, B: B), tform.count == 4  else {
            return nil
        }
        return PointTransformAffine(m: simd_double2x2(SIMD2<Double>(tform[0], -tform[1]),
                                                      SIMD2<Double>(tform[1], tform[0])),
                                    b: simd_double2(tform[2], tform[3]))
    }
    
    static func pointToMetrix(_ point: simd_double2) -> [[Double]] {
        [[Double(point.x), Double(point.y), 1, 0],
         [Double(point.y), -Double(point.x), 0, 1]]
    }
    
    static func pointToVector(_ point: simd_double2) -> [Double] {
        [Double(point.x), Double(point.y)]
    }
    
    static func getFacePartsDlib5(size: simd_double2, padding: Double) ->
    [simd_double2] {
        var p0 = simd_double2(0.8595674595992, 0.2134981538014)
        var p1 = simd_double2(0.6460604764104, 0.2289674387677)
        var p2 = simd_double2(0.1205750620789, 0.2137274526848)
        var p3 = simd_double2(0.3340850613712, 0.2290642403242)
        var p4 = simd_double2(0.4901123135679, 0.6277975316475)
        
        p0 = (padding+p0)/(2*padding+1)
        p1 = (padding+p1)/(2*padding+1)
        p2 = (padding+p2)/(2*padding+1)
        p3 = (padding+p3)/(2*padding+1)
        p4 = (padding+p4)/(2*padding+1)
        
        return [p2 * size, p3 * size, p1 * size, p0 * size, p4 * size]
    }
    
    static func getFacePartsSphereFace5(size: simd_double2, padding: Double) -> [simd_double2] {
        
        
        var p0 = simd_double2(0.34191607142857144, 0.4615741071428571)
        var p1 = simd_double2(0.6565339285714286, 0.4598339285714285)
        var p2 = simd_double2(0.500225, 0.6405053571428571)
        var p3 = simd_double2(0.3709758928571429, 0.8246919642857142)
        var p4 = simd_double2(0.6315169642857142, 0.8232508928571428)
        
        p0 = (padding+p0)/(2*padding+1)
        p1 = (padding+p1)/(2*padding+1)
        p2 = (padding+p2)/(2*padding+1)
        p3 = (padding+p3)/(2*padding+1)
        p4 = (padding+p4)/(2*padding+1)
        
        return [p0 * size, p1 * size, p2 * size, p3 * size, p4 * size]
    }

    
    static func getFaceParts68(size: simd_double2, padding: Double) -> [simd_double2] {
        var mean_face_shape_x: [Double] {[
            0.000213256, 0.0752622, 0.18113, 0.29077, 0.393397, 0.586856, 0.689483, 0.799124,
            0.904991, 0.98004, 0.490127, 0.490127, 0.490127, 0.490127, 0.36688, 0.426036,
            0.490127, 0.554217, 0.613373, 0.121737, 0.187122, 0.265825, 0.334606, 0.260918,
            0.182743, 0.645647, 0.714428, 0.793132, 0.858516, 0.79751, 0.719335, 0.254149,
            0.340985, 0.428858, 0.490127, 0.551395, 0.639268, 0.726104, 0.642159, 0.556721,
            0.490127, 0.423532, 0.338094, 0.290379, 0.428096, 0.490127, 0.552157, 0.689874,
            0.553364, 0.490127, 0.42689
        ]}
        var mean_face_shape_y: [Double] {[
            0.106454, 0.038915, 0.0187482, 0.0344891, 0.0773906, 0.0773906, 0.0344891,
            0.0187482, 0.038915, 0.106454, 0.203352, 0.307009, 0.409805, 0.515625, 0.587326,
            0.609345, 0.628106, 0.609345, 0.587326, 0.216423, 0.178758, 0.179852, 0.231733,
            0.245099, 0.244077, 0.231733, 0.179852, 0.178758, 0.216423, 0.244077, 0.245099,
            0.780233, 0.745405, 0.727388, 0.742578, 0.727388, 0.745405, 0.780233, 0.864805,
            0.902192, 0.909281, 0.902192, 0.864805, 0.784792, 0.778746, 0.785343, 0.778746,
            0.784792, 0.824182, 0.831803, 0.824182
        ]}
        var points: [simd_double2] = []
        for i in 17...67 {
            // Ignore the lower lip
            if ((55 <= i && i <= 59) || (65 <= i && i <= 67)) {
                continue
            }
            // Ignore the eyebrows
            if (17 <= i && i <= 26) {
                continue
            }
            if (49 == i || 53 == i || 60 == i || 64 == i) {
                continue
            }
            let x = (padding+mean_face_shape_x[i-17])/(2*padding+1)
            let y = (padding+mean_face_shape_y[i-17])/(2*padding+1)
            points.append(simd_double2(x, y)*size)
        }
        return points
    }
}
