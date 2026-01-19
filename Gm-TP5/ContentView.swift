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

struct ContentView: View {
    @State private var selectedQuestion: Question = .q1
    @State private var showWire: Bool = true
    @State private var subdivisions: Int = 3
    @State private var showBoundingBox: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Controls
            HStack(spacing: 16) {
                Picker("", selection: $selectedQuestion) {
                    ForEach(Question.allCases) { q in
                        Text(q.rawValue).tag(q)
                    }
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                Stepper(value: $subdivisions, in: 0...8) {
                    Text("Iterations: \(subdivisions)")
                }
                .frame(minWidth: 160)
                
                Divider()
                
                Toggle("Wire", isOn: $showWire)
                    .toggleStyle(.switch)
            }
            .padding(.horizontal)

            // Preview
            GeometryPreview(
                geometryBuilder: {
                    switch selectedQuestion {
                    case .q1:
                        ChaikinCurve(iterations: subdivisions)
                    case .q2:
                        LoopSubdivision(iterations: subdivisions)
                    }
                },
                showWire: showWire
            )
            .id("\(selectedQuestion.rawValue)-\(showWire)-\(subdivisions)")
            .frame(minHeight: 800)
        }
    }
}

#Preview {
    ContentView()
}
