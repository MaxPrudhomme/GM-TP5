//
//  Q1.swift
//  GM-TP4
//
//  Created by Max PRUDHOMME on 01/12/2025.
//

import simd
import SwiftUI
import SceneKit

func Q1(subdivisions: Int, showBoundingBox: Bool = false) -> SCNNode {
    let mesh = Mesh()
    
    try! mesh.load(named: "buddha")

    let lod = LOD(subdivisions: subdivisions, meshes: [mesh])
    
    lod.render()
    
    let final = Mesh(vertices: lod.vertices, indices: lod.indices)
    final.makeNormals()
    
    let parent = SCNNode()
    parent.addChildNode(final.makeNode())
    
    if showBoundingBox {
        let boxNode = BoundingBoxNode.create(min: lod.meshMin, max: lod.meshMax, subdivisions: subdivisions > 0 ? subdivisions : 1)
        parent.addChildNode(boxNode)
    }
    
    return parent
}
