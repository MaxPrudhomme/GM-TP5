//
//  LOD.swift
//  GM-TP4
//
//  Created by Max PRUDHOMME on 01/12/2025.
//

import simd
import SceneKit

class LOD {
    var subdivisions: Int
    var factor: Float
    var meshes: [Mesh]
    
    var vertices: [SIMD3<Float>] = []
    var indices: [UInt16] = []
    var voxels: [String: Voxel] = [:]
    
    var meshMin: SIMD3<Float> = .zero
    var meshMax: SIMD3<Float> = .zero
    
    init(subdivisions: Int = 1, meshes: [Mesh] = []) {
        self.subdivisions = subdivisions
        self.meshes = meshes
        
        self.factor = 1.0 / Float(subdivisions)
        
        normalize()
    }
    
    func normalize() {
        for mesh in meshes {
            mesh.center()
        }
        
        meshMin = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        meshMax = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        
        for mesh in meshes {
            for v in mesh.vertices {
                meshMin = simd_min(meshMin, v)
                meshMax = simd_max(meshMax, v)
            }
        }
        
        let maxExtent = max(meshMax.x - meshMin.x, meshMax.y - meshMin.y, meshMax.z - meshMin.z)
        let scale: Float = 2.0 / maxExtent
        let center = (meshMin + meshMax) * 0.5
        
        for mesh in meshes {
            for i in 0..<mesh.vertices.count {
                mesh.vertices[i] = (mesh.vertices[i] - center) * scale
            }
        }
        
        meshMin = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        meshMax = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        
        for mesh in meshes {
            for v in mesh.vertices {
                meshMin = simd_min(meshMin, v)
                meshMax = simd_max(meshMax, v)
            }
        }
    }
    
    func voxelKey(for v: SIMD3<Float>, vsx: Float, vsy: Float, vsz: Float, meshMin: SIMD3<Float>) -> String {
        var gx = Int((v.x - meshMin.x) / vsx)
        var gy = Int((v.y - meshMin.y) / vsy)
        var gz = Int((v.z - meshMin.z) / vsz)
        gx = max(0, min(subdivisions-1, gx))
        gy = max(0, min(subdivisions-1, gy))
        gz = max(0, min(subdivisions-1, gz))
        return "\(gx)-\(gy)-\(gz)"
    }
    
    func makeVoxels(vsx: Float, vsy: Float, vsz: Float) {
        for x in 0...subdivisions {
            for y in 0...subdivisions {
                for z in 0...subdivisions {
                    let px = meshMin.x + (Float(x) + 0.5) * vsx
                    let py = meshMin.y + (Float(y) + 0.5) * vsy
                    let pz = meshMin.z + (Float(z) + 0.5) * vsz
                    
                    voxels["\(x)-\(y)-\(z)"] = Voxel(size: 1.0, center: SIMD3<Float>(px, py, pz), vertices: [], newVertex: nil)
                }
            }
        }
    }
    
    
    func render() {
        vertices.removeAll()
        indices.removeAll()
        
        if subdivisions == -1 {
            for mesh in meshes {
                vertices += mesh.vertices
                indices += mesh.indices
            }
        } else {
            let vsX = (meshMax.x - meshMin.x) / Float(subdivisions)
            let vsY = (meshMax.y - meshMin.y) / Float(subdivisions)
            let vsZ = (meshMax.z - meshMin.z) / Float(subdivisions)
            
            makeVoxels(vsx: vsX, vsy: vsY, vsz: vsZ)
            
            for mesh in meshes {
                for vertex in mesh.vertices {
                    let gx = Int((vertex.x - meshMin.x) / vsX)
                    let gy = Int((vertex.y - meshMin.y) / vsY)
                    let gz = Int((vertex.z - meshMin.z) / vsZ)
                    
                    voxels["\(gx)-\(gy)-\(gz)"]?.vertices.append(vertex)
                }
            }
            
            for key in voxels.keys {
                guard var v = voxels[key] else { continue }
                let count = v.vertices.count
                if count > 0 {
                    let sum = v.vertices.reduce(SIMD3<Float>(repeating: 0)) { $0 + $1 }
                    v.newVertex = sum / Float(count)
                } else {
                    v.newVertex = v.center
                }
                voxels[key] = v
            }
        
            var keyToIndex: [String: UInt16] = [:]

            for (key, voxel) in voxels {
                guard let nv = voxel.newVertex else { continue }
                let index = UInt16(vertices.count)
                vertices.append(nv)
                keyToIndex[key] = index
            }
            
            for mesh in meshes {
                for i in stride(from: 0, to: mesh.indices.count, by: 3) {
                    let va = mesh.vertices[Int(mesh.indices[i])]
                    let vb = mesh.vertices[Int(mesh.indices[i + 1])]
                    let vc = mesh.vertices[Int(mesh.indices[i + 2])]

                    let keyA = voxelKey(for: va, vsx: vsX, vsy: vsY, vsz: vsZ, meshMin: meshMin)
                    let keyB = voxelKey(for: vb, vsx: vsX, vsy: vsY, vsz: vsZ, meshMin: meshMin)
                    let keyC = voxelKey(for: vc, vsx: vsX, vsy: vsY, vsz: vsZ, meshMin: meshMin)

                    guard let idA = keyToIndex[keyA],
                          let idB = keyToIndex[keyB],
                          let idC = keyToIndex[keyC] else { continue }

                    if idA == idB || idA == idC || idB == idC { continue }

                    indices.append(contentsOf: [idA, idB, idC])
                }
            }
        }
    }
}

struct Voxel {
    let size: Float
    let center: SIMD3<Float>
    var vertices: [SIMD3<Float>]
    var newVertex: SIMD3<Float>?
}

