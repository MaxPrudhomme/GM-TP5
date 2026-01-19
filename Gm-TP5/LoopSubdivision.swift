//
//  LoopSubdivision.swift
//  GM-TP5
//
//  Created by Max PRUDHOMME on 19/01/2026.
//

import SceneKit
import simd

/// Loop subdivision algorithm for triangle meshes
/// Subdivides each triangle into 4 smaller triangles and smooths the mesh
func LoopSubdivision(iterations: Int, meshType: MeshType = .tetrahedron) -> SCNNode {
    // Load or create the initial mesh
    var mesh: Mesh
    
    switch meshType {
    case .tetrahedron:
        mesh = createSimpleTetrahedron()
    case .cube:
        mesh = Mesh()
        do {
            try mesh.load(named: "cube", withExtension: "off")
            mesh.center()
            mesh.normalize()
        } catch {
            print("Error loading cube mesh: \(error)")
            // Fallback to tetrahedron
            mesh = createSimpleTetrahedron()
        }
    }
    
    // Apply Loop subdivision
    for _ in 0..<iterations {
        mesh = loopSubdivide(mesh: mesh)
    }
    
    // Generate normals for smooth shading
    mesh.makeNormals()
    
    return mesh.makeNode()
}

/// Performs one iteration of Loop subdivision
private func loopSubdivide(mesh: Mesh) -> Mesh {
    var newVertices: [SIMD3<Float>] = []
    var newIndices: [UInt16] = []
    
    // Build adjacency information
    var edgeToMidpoint: [Edge: Int] = [:]
    var vertexToTriangles: [Int: [Int]] = [:]
    var vertexNeighbors: [Int: Set<Int>] = [:]
    
    // Build vertex neighbor information
    for i in stride(from: 0, to: mesh.indices.count, by: 3) {
        let i0 = Int(mesh.indices[i])
        let i1 = Int(mesh.indices[i + 1])
        let i2 = Int(mesh.indices[i + 2])
        let triIndex = i / 3
        
        vertexToTriangles[i0, default: []].append(triIndex)
        vertexToTriangles[i1, default: []].append(triIndex)
        vertexToTriangles[i2, default: []].append(triIndex)
        
        vertexNeighbors[i0, default: []].insert(i1)
        vertexNeighbors[i0, default: []].insert(i2)
        vertexNeighbors[i1, default: []].insert(i0)
        vertexNeighbors[i1, default: []].insert(i2)
        vertexNeighbors[i2, default: []].insert(i0)
        vertexNeighbors[i2, default: []].insert(i1)
    }
    
    // Step 1: Compute new positions for existing (odd) vertices using Loop weights
    var oddVertices: [SIMD3<Float>] = []
    for i in 0..<mesh.vertices.count {
        let neighbors = Array(vertexNeighbors[i] ?? [])
        let n = neighbors.count
        
        if n == 0 {
            oddVertices.append(mesh.vertices[i])
            continue
        }
        
        // Loop subdivision weights
        // β = (1/n) * (5/8 - (3/8 + 1/4 * cos(2π/n))^2)
        let angle = 2.0 * Float.pi / Float(n)
        let beta: Float
        if n == 3 {
            beta = 3.0 / 16.0
        } else {
            let temp = 3.0 / 8.0 + 0.25 * cos(angle)
            beta = (1.0 / Float(n)) * (5.0 / 8.0 - temp * temp)
        }
        
        var newPos = mesh.vertices[i] * (1.0 - Float(n) * beta)
        for neighborIdx in neighbors {
            newPos += mesh.vertices[neighborIdx] * beta
        }
        
        oddVertices.append(newPos)
    }
    
    newVertices = oddVertices
    
    // Step 2: Compute new (even) vertices for edge midpoints
    for i in stride(from: 0, to: mesh.indices.count, by: 3) {
        let edges = [
            (Int(mesh.indices[i]), Int(mesh.indices[i + 1])),
            (Int(mesh.indices[i + 1]), Int(mesh.indices[i + 2])),
            (Int(mesh.indices[i + 2]), Int(mesh.indices[i]))
        ]
        
        for (v0, v1) in edges {
            let edge = Edge(v0, v1)
            
            if edgeToMidpoint[edge] == nil {
                // Find the two triangles sharing this edge
                let p0 = mesh.vertices[v0]
                let p1 = mesh.vertices[v1]
                
                // Find opposite vertices
                var opposites: [SIMD3<Float>] = []
                
                for j in stride(from: 0, to: mesh.indices.count, by: 3) {
                    let t0 = Int(mesh.indices[j])
                    let t1 = Int(mesh.indices[j + 1])
                    let t2 = Int(mesh.indices[j + 2])
                    
                    let verts = Set([t0, t1, t2])
                    if verts.contains(v0) && verts.contains(v1) {
                        // This triangle contains the edge
                        let opposite = verts.subtracting([v0, v1]).first!
                        opposites.append(mesh.vertices[opposite])
                    }
                }
                
                let newVertex: SIMD3<Float>
                if opposites.count == 2 {
                    // Interior edge: 3/8 * (p0 + p1) + 1/8 * (opposite0 + opposite1)
                    newVertex = (p0 + p1) * 0.375 + (opposites[0] + opposites[1]) * 0.125
                } else {
                    // Boundary edge: simple midpoint
                    newVertex = (p0 + p1) * 0.5
                }
                
                let idx = newVertices.count
                newVertices.append(newVertex)
                edgeToMidpoint[edge] = idx
            }
        }
    }
    
    // Step 3: Build new triangles
    for i in stride(from: 0, to: mesh.indices.count, by: 3) {
        let v0 = Int(mesh.indices[i])
        let v1 = Int(mesh.indices[i + 1])
        let v2 = Int(mesh.indices[i + 2])
        
        // Get edge midpoints
        let m01 = edgeToMidpoint[Edge(v0, v1)]!
        let m12 = edgeToMidpoint[Edge(v1, v2)]!
        let m20 = edgeToMidpoint[Edge(v2, v0)]!
        
        // Create 4 new triangles
        // Corner triangles
        newIndices.append(contentsOf: [UInt16(v0), UInt16(m01), UInt16(m20)])
        newIndices.append(contentsOf: [UInt16(v1), UInt16(m12), UInt16(m01)])
        newIndices.append(contentsOf: [UInt16(v2), UInt16(m20), UInt16(m12)])
        
        // Center triangle
        newIndices.append(contentsOf: [UInt16(m01), UInt16(m12), UInt16(m20)])
    }
    
    return Mesh(vertices: newVertices, indices: newIndices)
}

/// Helper struct to represent an edge (order-independent)
private struct Edge: Hashable {
    let v0: Int
    let v1: Int
    
    init(_ a: Int, _ b: Int) {
        if a < b {
            v0 = a
            v1 = b
        } else {
            v0 = b
            v1 = a
        }
    }
}

/// Creates a simple tetrahedron mesh for testing
private func createSimpleTetrahedron() -> Mesh {
    let vertices: [SIMD3<Float>] = [
        SIMD3<Float>( 0.0,  1.0,  0.0),
        SIMD3<Float>(-1.0, -0.5,  1.0),
        SIMD3<Float>( 1.0, -0.5,  1.0),
        SIMD3<Float>( 0.0, -0.5, -1.0)
    ]
    
    let indices: [UInt16] = [
        0, 1, 2,  // front
        0, 2, 3,  // right
        0, 3, 1,  // left
        1, 3, 2   // bottom
    ]
    
    let mesh = Mesh(vertices: vertices, indices: indices)
    
    // Center and normalize
    mesh.center()
    mesh.normalize()
    
    return mesh
}
