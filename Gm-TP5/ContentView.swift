//
//  ContentView.swift
//  GM-TP4
//
//  Created by Max PRUDHOMME on 01/12/2025.
//

import SwiftUI
import SceneKit
import Combine

enum Question: String, CaseIterable, Identifiable {
    case q1 = "Chaikin"
    case q2 = "Loop"
    var id: String { rawValue }
}

enum MeshType: String, CaseIterable, Identifiable {
    case tetrahedron = "Tetrahedron"
    case cube = "Cube"
    var id: String { rawValue }
}

struct ContentView: View {
    @State private var selectedQuestion: Question = .q1
    @State private var showWire: Bool = true
    @State private var subdivisions: Int = 3
    @State private var selectedMesh: MeshType = .tetrahedron

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Picker("", selection: $selectedQuestion) {
                    ForEach(Question.allCases) { q in
                        Text(q.rawValue).tag(q)
                    }
                }
                .pickerStyle(.segmented)

                Spacer()

                if selectedQuestion == .q2 {
                    Picker("Mesh:", selection: $selectedMesh) {
                        ForEach(MeshType.allCases) { mesh in
                            Text(mesh.rawValue).tag(mesh)
                        }
                    }
                    .frame(width: 160)
                    
                    Divider()
                }

                Stepper(value: $subdivisions, in: 0...8) {
                    Text("Iterations: \(subdivisions)")
                }
                .frame(minWidth: 160)

                Divider()

                Toggle("Wire", isOn: $showWire)
                    .toggleStyle(.switch)
            }
            .padding(.horizontal)

            GeometryPreview(
                geometryBuilder: {
                    switch selectedQuestion {
                    case .q1:
                        ChaikinCurve(iterations: subdivisions)
                    case .q2:
                        LoopSubdivision(iterations: subdivisions, meshType: selectedMesh)
                    }
                },
                showWire: showWire
            )
            .id("\(selectedQuestion.rawValue)-\(showWire)-\(subdivisions)-\(selectedMesh.rawValue)")
            .frame(minHeight: 800)
        }
    }
}

#Preview {
    ContentView()
}
