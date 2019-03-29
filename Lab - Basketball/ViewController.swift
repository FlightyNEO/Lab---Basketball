//
//  ViewController.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 28/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

// Model Basketball post - https://www.cgtrader.com/free-3d-models/exterior/exterior-public/basketball-post


import ARKit

class ViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Private properties
    private let modelManager = ModelManager.manager
    private let configuration: ARWorldTrackingConfiguration? = nil
    private var postIsAdded = false
    
    private var sizeModel: ModelManager.Size {
        
        #if DEBUG
        return .quarter
        #else
        return .real
        #endif
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        #if DEBUG
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        #endif
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        guard !postIsAdded else { return }
        
        modelManager.addPost(to: node, size: sizeModel, anchor: anchor) { _ in
            
            self.configuration?.planeDetection = []
            self.postIsAdded = true
            
        }
        
    }
    
}
