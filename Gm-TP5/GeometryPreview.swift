//
//  GeometryPreview.swift
//  GM-TP4
//
//  Created by Max PRUDHOMME on 01/12/2025.
//


import SwiftUI
import SceneKit

struct GeometryPreview: NSViewRepresentable {
    var geometryBuilder: (() -> SCNNode)?
    let showWire: Bool

    func makeNSView(context: Context) -> SCNView {
        let view = CustomSCNView()
        view.scene = buildScene()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = NSColor.gray.withAlphaComponent(0.1)
        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        nsView.scene?.rootNode.enumerateChildNodes { node, _ in
            if node.name == "meshWire" {
                node.isHidden = !showWire
            }
        }
    }

    class CustomSCNView: SCNView {
        private var lastMiddleDrag: CGPoint?

        override func otherMouseDown(with event: NSEvent) {
            lastMiddleDrag = event.locationInWindow
        }

        override func otherMouseDragged(with event: NSEvent) {
            guard let camera = pointOfView else { return }
            guard let last = lastMiddleDrag else {
                lastMiddleDrag = event.locationInWindow
                return
            }

            let pos = event.locationInWindow
            let dx = Float(pos.x - last.x)
            let dy = Float(pos.y - last.y)
            lastMiddleDrag = pos

            let factor: Float = 0.01
            let right = camera.simdWorldRight * -dx * factor
            let up = camera.simdWorldUp * -dy * factor
            camera.simdPosition += right + up
        }

        override func otherMouseUp(with event: NSEvent) {
            lastMiddleDrag = nil
        }

        override func scrollWheel(with event: NSEvent) {
            guard let camera = pointOfView else { return }
            let zoomFactor: Float = Float(-event.scrollingDeltaY) * 0.01
            camera.localTranslate(by: SCNVector3(0, 0, zoomFactor))
        }
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        if let node = geometryBuilder?() {
            scene.rootNode.addChildNode(node)
        }

        // --- lights ---
        let light = SCNLight()
        light.type = .omni
        light.intensity = 2000
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(20, 30, 4)
        scene.rootNode.addChildNode(lightNode)

        let amb = SCNLight()
        amb.type = .ambient
        amb.intensity = 100
        let ambNode = SCNNode()
        ambNode.light = amb
        scene.rootNode.addChildNode(ambNode)

        // --- camera ---
        let cam = SCNCamera()
        let camNode = SCNNode()
        camNode.camera = cam
        camNode.position = SCNVector3(0, 0, 5)
        camNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camNode)

        scene.background.contents = NSColor.gray.withAlphaComponent(0.2)
        return scene
    }
}
