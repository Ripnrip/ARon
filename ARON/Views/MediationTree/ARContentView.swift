//
//  ContentView.swift
//  ModelPicker
//
//  Created by Fernando Fernandes on 24.07.20.
//

import SwiftUI
import RealityKit

struct ARContentView: View {

    // MARK: - Properties

    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    @State private var currentModel: AnchorEntity?

    private var models: [Model] = {
        let fileManager = FileManager.default
        guard let path = Bundle.main.resourcePath,
              let files = try? fileManager.contentsOfDirectory(atPath: path) else {
            return []
        }
        let usdz = files
            .filter { $0.hasSuffix(".usdz") }
            .compactMap { $0.replacingOccurrences(of: ".usdz", with: "") }
            .compactMap { Model(modelName: $0 ) }
        let obj = files
            .filter { $0.hasSuffix(".obj") }
            .compactMap { $0.replacingOccurrences(of: ".obj", with: "") }
            .compactMap { Model(modelName: $0 ) }
        return usdz + obj
    }()

    // MARK: Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewRepresentable(
                modelConfirmedForPlacement: $modelConfirmedForPlacement, currentModel: $currentModel
            )

            if isPlacementEnabled {
                PlacementButtonView(
                    isPlacementEnabled: $isPlacementEnabled,
                    selectedModel: $selectedModel,
                    modelConfirmedForPlacement: $modelConfirmedForPlacement
                )
            } else {
                ModelPickerView(
                    isPlacementEnabled: $isPlacementEnabled,
                    selectedModel: $selectedModel,
                    models: models
                )
            }
        }
    }
}

// MARK: - Preview

//#if DEBUG
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ARContentView()
//    }
//}
//#endif
