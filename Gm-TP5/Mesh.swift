//
//  Mesh.swift
//  GM-TP4
//
//  Created by Max PRUDHOMME on 01/12/2025.
//


import SceneKit
import SwiftUI
import simd

class Mesh {
    static var renderWire: Bool = true

    var vertices: [SIMD3<Float>]
    var indices: [UInt16]
    var normals: [SIMD3<Float>] = []

    init(vertices: [SIMD3<Float>] = [], indices: [UInt16] = []) {
        self.vertices = vertices
        self.indices = indices
    }
    
    func makeNode() -> SCNNode {
        let vsrc = SCNGeometrySource(
            vertices: vertices.map { SCNVector3($0.x, $0.y, $0.z) }
        )
        let nrm = normals.isEmpty
            ? Array(repeating: SIMD3<Float>(0, 0, 1), count: vertices.count)
            : normals
        let nsrc = SCNGeometrySource(
            normals: nrm.map { SCNVector3($0.x, $0.y, $0.z) }
        )

        let indicesData = indices.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }

        let elem = SCNGeometryElement(
            data: indicesData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<UInt16>.size
        )

        // constant-shaded fill
        let solid = SCNGeometry(sources: [vsrc, nsrc], elements: [elem])
        let fillMat = SCNMaterial()
        fillMat.lightingModel = .constant
        #if os(macOS)
        fillMat.diffuse.contents = NSColor.white
        #endif
        fillMat.isDoubleSided = true  // fixes inside-out appearance
        solid.materials = [fillMat]

        // optional wire overlay
        let wire = SCNGeometry(sources: [vsrc, nsrc], elements: [elem])
        let wireMat = SCNMaterial()
        wireMat.fillMode = .lines
        wireMat.lightingModel = .constant
        #if os(macOS)
        wireMat.diffuse.contents = NSColor.black
        #else
        wireMat.diffuse.contents = UIColor.black
        #endif
        wireMat.isDoubleSided = true
        wire.materials = [wireMat]

        let parent = SCNNode()
        parent.name = "meshParent"
        parent.addChildNode(SCNNode(geometry: solid))

        if Mesh.renderWire {
            let wireNode = SCNNode(geometry: wire)
            wireNode.name = "meshWire"
            parent.addChildNode(wireNode)
        }

        return parent
    }
    
    func parse(from path: String) throws {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            var lines = content
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }

            guard lines.first == "OFF" else { throw NSError(domain: "OFFParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing OFF header"]) }
            lines.removeFirst()
            
            let counts = lines.removeFirst().split(separator: " ").compactMap { Int($0) }
            guard counts.count >= 3 else { throw NSError(domain: "OFFParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid counts line"]) }

            let vertexCount = counts[0]
            let faceCount = counts[1]

            vertices.removeAll()
            for i in 0..<vertexCount {
                let parts = lines.removeFirst().split(separator: " ").compactMap { Float($0) }
                guard parts.count == 3 else {
                    throw NSError(
                        domain: "OFFParser",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid vertex line \(i)"]
                    )
                }
                vertices.append(SIMD3(parts[0], parts[1], parts[2]))
            }

            indices.removeAll()
            for i in 0..<faceCount {
                let parts = lines.removeFirst().split(separator: " ").compactMap { Int($0) }
                guard parts.count >= 4 else {
                    throw NSError(
                        domain: "OFFParser",
                        code: 4,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid face line \(i)"]
                    )
                }
                let faceIndices = Array(parts[1...])
                for idx in faceIndices {
                    indices.append(UInt16(idx))
                }
            }

            normals = Array(repeating: SIMD3<Float>(0, 0, 1), count: vertices.count)
        }
    
    func load(named name: String, withExtension ext: String = "off") throws {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            throw NSError(domain: "Mesh", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Failed to find \(name).\(ext) in bundle."
            ])
        }
        try parse(from: url.path)
    }
    
    func center() {
        let sum = vertices.reduce(SIMD3<Float>(0, 0, 0)) { $0 + $1 }
        let center = sum / Float(vertices.count)
        
        for i in 0..<vertices.count {
            vertices[i] -= center
        }
    }
    
    func normalize() {
        let maxCoord = vertices.reduce(Float(0)) { currentMax, vertex in
            let vertexMax = max(abs(vertex.x), abs(vertex.y), abs(vertex.z))
            return max(currentMax, vertexMax)
        }
        
        for i in 0..<vertices.count {
            let scale: Float = 1.0 / maxCoord
            vertices[i] *= scale
        }
    }
    
    func makeNormals() {
        var normalCounts = Array(repeating: 0, count: vertices.count)
        normals = Array(repeating: SIMD3<Float>(0, 0, 0), count: vertices.count)
        
        for i in stride(from: 0, to: indices.count, by: 3) {
            let ia = Int(indices[i])
            let ib = Int(indices[i + 1])
            let ic = Int(indices[i + 2])
            
            guard ia < vertices.count, ib < vertices.count, ic < vertices.count else { continue }
            
            let a = vertices[ia]
            let b = vertices[ib]
            let c = vertices[ic]
            let faceNormal = simd_normalize(simd_cross(b - a, c - a))
            
            normals[ia] += faceNormal
            normals[ib] += faceNormal
            normals[ic] += faceNormal
            normalCounts[ia] += 1
            normalCounts[ib] += 1
            normalCounts[ic] += 1
        }
        
        for i in 0..<normals.count {
            if normalCounts[i] > 0 {
                normals[i] /= Float(normalCounts[i])
                normals[i] = simd_normalize(normals[i])
            }
        }
    }
    
    func intersects(voxel: Voxel) -> Bool {
        guard !vertices.isEmpty else { return false }
        
        // Check each triangle for intersection with the voxel (AABB)
        for i in stride(from: 0, to: indices.count, by: 3) {
            guard i + 2 < indices.count else { continue }
            let ia = Int(indices[i])
            let ib = Int(indices[i + 1])
            let ic = Int(indices[i + 2])
            
            guard ia < vertices.count, ib < vertices.count, ic < vertices.count else { continue }
            
            let v0 = vertices[ia]
            let v1 = vertices[ib]
            let v2 = vertices[ic]
            
            if triangleIntersectsAABB(v0: v0, v1: v1, v2: v2, center: voxel.center, halfSize: voxel.size * 0.5) {
                return true
            }
        }
        return false
    }
    
    // Triangle-AABB intersection using Separating Axis Theorem
    private func triangleIntersectsAABB(v0: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>, center: SIMD3<Float>, halfSize: Float) -> Bool {
        // Translate triangle to AABB center
        let t0 = v0 - center
        let t1 = v1 - center
        let t2 = v2 - center
        
        // Triangle edges
        let e0 = t1 - t0
        let e1 = t2 - t1
        let e2 = t0 - t2
        
        let h = SIMD3<Float>(repeating: halfSize)
        
        // Test 9 axis (cross products of edges with AABB normals)
        let axes: [SIMD3<Float>] = [
            SIMD3(0, -e0.z, e0.y), SIMD3(e0.z, 0, -e0.x), SIMD3(-e0.y, e0.x, 0),
            SIMD3(0, -e1.z, e1.y), SIMD3(e1.z, 0, -e1.x), SIMD3(-e1.y, e1.x, 0),
            SIMD3(0, -e2.z, e2.y), SIMD3(e2.z, 0, -e2.x), SIMD3(-e2.y, e2.x, 0)
        ]
        
        for axis in axes {
            let len = simd_length(axis)
            if len < 1e-6 { continue }
            
            let p0 = simd_dot(t0, axis)
            let p1 = simd_dot(t1, axis)
            let p2 = simd_dot(t2, axis)
            
            let r = h.x * abs(axis.x) + h.y * abs(axis.y) + h.z * abs(axis.z)
            
            let minP = min(p0, p1, p2)
            let maxP = max(p0, p1, p2)
            
            if minP > r || maxP < -r {
                return false
            }
        }
        
        // Test AABB face normals (X, Y, Z axes)
        let minT = simd_min(simd_min(t0, t1), t2)
        let maxT = simd_max(simd_max(t0, t1), t2)
        
        if minT.x > h.x || maxT.x < -h.x { return false }
        if minT.y > h.y || maxT.y < -h.y { return false }
        if minT.z > h.z || maxT.z < -h.z { return false }
        
        // Test triangle normal
        let normal = simd_cross(e0, e1)
        let d = simd_dot(normal, t0)
        let r = h.x * abs(normal.x) + h.y * abs(normal.y) + h.z * abs(normal.z)
        
        if abs(d) > r {
            return false
        }
        
        return true
    }
}

