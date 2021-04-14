//
//  VNFaceObservation + Extension.swift
//  LookKit
//
//  Created by Amir Lahav on 13/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Vision
#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension VNFaceObservation {
    func facePointsVectorsDlib5(in imageSize: CGSize) -> [simd_double2] {
        guard let allPoints = self.landmarks?.allPoints, allPoints.pointCount == 76 else {
            fatalError("You have to give a 5 point face landmarking output to this function.")
        }
        let points = allPoints.pointsInImage(imageSize: imageSize)
        let featurePoints = [points[0], points[1], points[8], points[7], points[52]]
        return featurePoints.map({ (point) -> CGPoint in
            CGPoint(x: point.x, y: imageSize.height - point.y)
        }).map({$0.toVector()})
    }
    
    func facePointsVectorsSphereFace5(in imageSize: CGSize) -> [simd_double2] {
        guard let allPoints = self.landmarks?.allPoints, allPoints.pointCount == 76 else {
            fatalError("You have to give a 5 point face landmarking output to this function.")
        }
        let points = allPoints.pointsInImage(imageSize: imageSize)
        let featurePoints = [points[6], points[13], points[52], points[26], points[35]]
        return featurePoints.map({ (point) -> CGPoint in
            CGPoint(x: point.x, y: imageSize.height - point.y)
        }).map({$0.toVector()})
    }
    
    func facePointsVectors76(in imageSize: CGSize) -> [simd_double2] {
        guard let allPoints = self.landmarks?.allPoints, allPoints.pointCount == 76 else {
            fatalError("You have to give a 5 point face landmarking output to this function.")
        }
        let points = allPoints.pointsInImage(imageSize: imageSize)
        let featurePoints = [points[46], points[47], points[48], points[49], points[54],
                             points[53], points[52], points[51], points[50], points[0],
                             points[4], points[5], points[1], points[3], points[2],
                             points[8], points[12], points[11], points[7], points[9],
                             points[10], points[26], points[29], points[30], points[31],
                             points[34], points[42], points[40], points[43]]
        return featurePoints.map({ (point) -> CGPoint in
            CGPoint(x: point.x, y: imageSize.height - point.y)
        }).map({$0.toVector()})
    }
}
