//
//  ARViewRepresentable.swift
//  ModelPicker
//
//  Created by Fernando Fernandes on 24.07.20.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewRepresentable: UIViewRepresentable {

    // MARK: - Properties

    @Binding var modelConfirmedForPlacement: Model?
    @Binding var currentModel:AnchorEntity?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> ARView {
        CustomARView(frame: .zero)
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        guard let model = modelConfirmedForPlacement else { return }

        if let modelEntity = model.modelEntity {
            print("Adding model to scene: \(model.modelName)")
            let anchorEntity = AnchorEntity(plane: .any)
            anchorEntity.setScale(SIMD3.init(x: 0.2, y: 0.2, z: 0.2), relativeTo: modelEntity)
            anchorEntity.addChild(modelEntity .clone(recursive: true))
            uiView.scene.addAnchor(anchorEntity)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 3.0,
                                 animations: {
                                    anchorEntity.setScale(SIMD3.init(x: 2.0, y: 2.0, z: 2.0), relativeTo: modelEntity)
                                    //anchorEntity.anima
                                 })}
        } else {
            print("Unable to load modelEntity for: \(model.modelName)")
        }

        DispatchQueue.main.async {
            modelConfirmedForPlacement = nil
        }
    }
}
