//
//  Utils.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 29/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

//import Darwin
import ARKit

extension Float: DegreesToRadiansProtocol { }
extension Double: DegreesToRadiansProtocol { }

protocol DegreesToRadiansProtocol: FloatingPoint, ExpressibleByFloatLiteral { }

extension DegreesToRadiansProtocol {
    var radians: Self {
        return self * .pi / 180.0
    }
}


extension SCNVector3 {

    init(simd3: simd_float3) {
        self.init(x: Float(simd3.x), y: Float(simd3.y), z: Float(simd3.z))
    }
    
    static func +(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
    }

}

extension UISegmentedControl {
    
    /// Replace the current segments with new ones using a given sequence of string.
    /// - parameter withTitles:     The titles for the new segments.
    public func replaceSegments<T: Sequence>(withTitles: T) where T.Iterator.Element == String {
        removeAllSegments()
        for title in withTitles {
            insertSegment(withTitle: title, at: numberOfSegments, animated: false)
        }
    }
}
