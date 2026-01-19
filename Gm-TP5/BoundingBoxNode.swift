//
//  BoundingBoxNode.swift
//  GM-TP4
//
//  Created by Max PRUDHOMME on 01/12/2025.
//

import SceneKit

class BoundingBoxNode {
    static func create(min: SIMD3<Float>, max: SIMD3<Float>, subdivisions: Int = 1) -> SCNNode {
        let corners: [SIMD3<Float>] = [
            SIMD3(min.x, min.y, min.z),
            SIMD3(max.x, min.y, min.z),
            SIMD3(max.x, max.y, min.z),
            SIMD3(min.x, max.y, min.z),
            SIMD3(min.x, min.y, max.z),
            SIMD3(max.x, min.y, max.z),
            SIMD3(max.x, max.y, max.z),
            SIMD3(min.x, max.y, max.z)
        ]
        
        let faceIndices: [UInt16] = [
            0, 2, 1, 0, 3, 2,
            4, 5, 6, 4, 6, 7,
            3, 7, 6, 3, 6, 2,
            0, 1, 5, 0, 5, 4,
            0, 4, 7, 0, 7, 3,
            1, 2, 6, 1, 6, 5
        ]
        
        let edgeIndices: [UInt16] = [
            0, 1, 1, 2, 2, 3, 3, 0,
            4, 5, 5, 6, 6, 7, 7, 4,
            0, 4, 1, 5, 2, 6, 3, 7
        ]
        
        let parent = SCNNode()
        
        let vsrc = SCNGeometrySource(
            vertices: corners.map { SCNVector3($0.x, $0.y, $0.z) }
        )
        let normals = Array(repeating: SCNVector3(0, 0, 1), count: corners.count)
        let nsrc = SCNGeometrySource(normals: normals)
        
        let faceData = faceIndices.withUnsafeBufferPointer { Data(buffer: $0) }
        let faceElem = SCNGeometryElement(
            data: faceData,
            primitiveType: .triangles,
            primitiveCount: faceIndices.count / 3,
            bytesPerIndex: MemoryLayout<UInt16>.size
        )
        
        let faceGeometry = SCNGeometry(sources: [vsrc, nsrc], elements: [faceElem])
        let faceMaterial = SCNMaterial()
        faceMaterial.lightingModel = .constant
        faceMaterial.isDoubleSided = true
        #if os(macOS)
        faceMaterial.diffuse.contents = NSColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 0.25)
        #else
        faceMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 0.25)
        #endif
        faceMaterial.transparency = 0.25
        faceMaterial.blendMode = .alpha
        faceGeometry.materials = [faceMaterial]
        
        let faceNode = SCNNode(geometry: faceGeometry)
        parent.addChildNode(faceNode)
        
        let edgeData = edgeIndices.withUnsafeBufferPointer { Data(buffer: $0) }
        let edgeElem = SCNGeometryElement(
            data: edgeData,
            primitiveType: .line,
            primitiveCount: edgeIndices.count / 2,
            bytesPerIndex: MemoryLayout<UInt16>.size
        )
        
        let edgeGeometry = SCNGeometry(sources: [vsrc], elements: [edgeElem])
        let edgeMaterial = SCNMaterial()
        edgeMaterial.lightingModel = .constant
        #if os(macOS)
        edgeMaterial.diffuse.contents = NSColor(red: 1.0, green: 0.0, blue: 0.6, alpha: 1.0)
        #else
        edgeMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.6, alpha: 1.0)
        #endif
        edgeGeometry.materials = [edgeMaterial]
        
        let edgeNode = SCNNode(geometry: edgeGeometry)
        parent.addChildNode(edgeNode)
        
        if subdivisions > 1 {
            let gridNode = createGridLines(min: min, max: max, subdivisions: subdivisions)
            parent.addChildNode(gridNode)
        }
        
        return parent
    }
    
    private static func createGridLines(min: SIMD3<Float>, max: SIMD3<Float>, subdivisions: Int) -> SCNNode {
        var gridVertices: [SIMD3<Float>] = []
        var gridIndices: [UInt32] = []
        
        let maxExtent = Swift.max(max.x - min.x, max.y - min.y, max.z - min.z)
        let step = maxExtent / Float(subdivisions)
        
        let countX = Int(ceil((max.x - min.x) / step))
        let countY = Int(ceil((max.y - min.y) / step))
        let countZ = Int(ceil((max.z - min.z) / step))
        
        for face in [min.z, max.z] {
            for i in 0...countX {
                let x = min.x + Float(i) * step
                if x > max.x + 0.001 { continue }
                let clampedX = Swift.min(x, max.x)
                let idx = UInt32(gridVertices.count)
                gridVertices.append(SIMD3(clampedX, min.y, face))
                gridVertices.append(SIMD3(clampedX, max.y, face))
                gridIndices.append(idx)
                gridIndices.append(idx + 1)
            }
            // Horizontal lines (along X)
            for i in 0...countY {
                let y = min.y + Float(i) * step
                if y > max.y + 0.001 { continue }
                let clampedY = Swift.min(y, max.y)
                let idx = UInt32(gridVertices.count)
                gridVertices.append(SIMD3(min.x, clampedY, face))
                gridVertices.append(SIMD3(max.x, clampedY, face))
                gridIndices.append(idx)
                gridIndices.append(idx + 1)
            }
        }
        
        for face in [min.y, max.y] {
            for i in 0...countX {
                let x = min.x + Float(i) * step
                if x > max.x + 0.001 { continue }
                let clampedX = Swift.min(x, max.x)
                let idx = UInt32(gridVertices.count)
                gridVertices.append(SIMD3(clampedX, face, min.z))
                gridVertices.append(SIMD3(clampedX, face, max.z))
                gridIndices.append(idx)
                gridIndices.append(idx + 1)
            }
            for i in 0...countZ {
                let z = min.z + Float(i) * step
                if z > max.z + 0.001 { continue }
                let clampedZ = Swift.min(z, max.z)
                let idx = UInt32(gridVertices.count)
                gridVertices.append(SIMD3(min.x, face, clampedZ))
                gridVertices.append(SIMD3(max.x, face, clampedZ))
                gridIndices.append(idx)
                gridIndices.append(idx + 1)
            }
        }
        
        for face in [min.x, max.x] {
            for i in 0...countY {
                let y = min.y + Float(i) * step
                if y > max.y + 0.001 { continue }
                let clampedY = Swift.min(y, max.y)
                let idx = UInt32(gridVertices.count)
                gridVertices.append(SIMD3(face, clampedY, min.z))
                gridVertices.append(SIMD3(face, clampedY, max.z))
                gridIndices.append(idx)
                gridIndices.append(idx + 1)
            }
            for i in 0...countZ {
                let z = min.z + Float(i) * step
                if z > max.z + 0.001 { continue }
                let clampedZ = Swift.min(z, max.z)
                let idx = UInt32(gridVertices.count)
                gridVertices.append(SIMD3(face, min.y, clampedZ))
                gridVertices.append(SIMD3(face, max.y, clampedZ))
                gridIndices.append(idx)
                gridIndices.append(idx + 1)
            }
        }
        
        let vsrc = SCNGeometrySource(vertices: gridVertices.map { SCNVector3($0.x, $0.y, $0.z) })
        let gridData = gridIndices.withUnsafeBufferPointer { Data(buffer: $0) }
        let gridElem = SCNGeometryElement(
            data: gridData,
            primitiveType: .line,
            primitiveCount: gridIndices.count / 2,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )
        
        let gridGeometry = SCNGeometry(sources: [vsrc], elements: [gridElem])
        let gridMaterial = SCNMaterial()
        gridMaterial.lightingModel = .constant
        #if os(macOS)
        gridMaterial.diffuse.contents = NSColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 0.6)
        #else
        gridMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 0.6)
        #endif
        gridGeometry.materials = [gridMaterial]
        
        return SCNNode(geometry: gridGeometry)
    }
}
