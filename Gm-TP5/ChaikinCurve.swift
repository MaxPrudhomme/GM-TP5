//
//  ChaikinCurve.swift
//  GM-TP5
//
//  Created by Max PRUDHOMME on 19/01/2026.
//

import SceneKit
import simd

/// Chaikin's corner-cutting algorithm for curve subdivision
/// Each iteration replaces each line segment with two segments by cutting corners
func ChaikinCurve(iterations: Int) -> SCNNode {
    // Initial control points forming a simple shape
    var points: [SIMD3<Float>] = [
        SIMD3<Float>(-0.8, -0.5, 0),
        SIMD3<Float>(-0.5,  0.6, 0),
        SIMD3<Float>( 0.0, -0.3, 0),
        SIMD3<Float>( 0.5,  0.7, 0),
        SIMD3<Float>( 0.8, -0.4, 0)
    ]
    
    // Apply Chaikin subdivision
    for _ in 0..<iterations {
        points = chaikinSubdivide(points: points)
    }
    
    // Create line geometry to visualize the curve
    let parent = SCNNode()
    
    // Draw the curve as connected line segments
    for i in 0..<points.count - 1 {
        let line = createLine(from: points[i], to: points[i + 1])
        parent.addChildNode(line)
    }
    
    // Draw control points
    for point in points {
        let sphere = SCNSphere(radius: 0.015)
        let material = SCNMaterial()
        material.lightingModel = .constant
        #if os(macOS)
        material.diffuse.contents = NSColor.systemRed
        #else
        material.diffuse.contents = UIColor.systemRed
        #endif
        sphere.materials = [material]
        
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(point.x, point.y, point.z)
        parent.addChildNode(node)
    }
    
    return parent
}

/// Performs one iteration of Chaikin subdivision
/// For each edge, create two new points at 1/4 and 3/4 positions
private func chaikinSubdivide(points: [SIMD3<Float>]) -> [SIMD3<Float>] {
    guard points.count >= 2 else { return points }
    
    var newPoints: [SIMD3<Float>] = []
    
    for i in 0..<points.count - 1 {
        let p0 = points[i]
        let p1 = points[i + 1]
        
        // Q point: 3/4 from p0, 1/4 from p1
        let q = p0 * 0.75 + p1 * 0.25
        
        // R point: 1/4 from p0, 3/4 from p1
        let r = p0 * 0.25 + p1 * 0.75
        
        newPoints.append(q)
        newPoints.append(r)
    }
    
    return newPoints
}

/// Creates a line segment between two points
private func createLine(from start: SIMD3<Float>, to end: SIMD3<Float>) -> SCNNode {
    let vertices = [
        SCNVector3(start.x, start.y, start.z),
        SCNVector3(end.x, end.y, end.z)
    ]
    
    let vertexSource = SCNGeometrySource(vertices: vertices)
    
    let indices: [UInt16] = [0, 1]
    let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt16>.size)
    
    let element = SCNGeometryElement(
        data: indexData,
        primitiveType: .line,
        primitiveCount: 1,
        bytesPerIndex: MemoryLayout<UInt16>.size
    )
    
    let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
    
    let material = SCNMaterial()
    material.lightingModel = .constant
    #if os(macOS)
    material.diffuse.contents = NSColor.black
    #else
    material.diffuse.contents = UIColor.black
    #endif
    geometry.materials = [material]
    
    return SCNNode(geometry: geometry)
}
