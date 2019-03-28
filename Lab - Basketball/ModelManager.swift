//
//  ModelManager.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 28/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

import ARKit

struct ModelManager {
    
    // MARK: - Properties
    enum NodeModel: String {
        
        case post = "BasketballPost"
        //case ball = ""
        
        fileprivate var sceneName: String {
            
            switch self {
                
            case .post: return "art.scnassets/Basketball_Post/Basketball_Post.scn"
            //case .ball: return ""
                
            }
            
        }
        
    }
    
    // MARK: - Initialization
    private init() {}
    static var manager: ModelManager { return ModelManager.init() }
    
    // MARK - Errors
    enum NodeManagerError: Error {
        case fetchError(error: String)
    }
    
    // MARK: Private methods
    private func nodeFrom(_ sceneFile: String?) throws -> SCNNode {
        
        guard
            let sceneFile = sceneFile,
            let sceneNode = SCNScene(named: sceneFile)?.rootNode else {
                
                throw NodeManagerError.fetchError(error: "Not fined node for this name")
                
        }
        
        return sceneNode
    }
    
    private func fetch(_ model: NodeModel, completion: @escaping (Result<SCNNode, NodeManagerError>) -> ()) {
        
        do {
            
            let sceneNode = try nodeFrom(model.sceneName)
            
            guard let node = sceneNode.childNode(withName: model.rawValue, recursively: true) else {
                
                completion(.failure(.fetchError(error: "Not fined node for this name")))
                return
                
            }
            
            completion(.success(node))
            
        } catch (let error) {
            
            completion(.failure(.fetchError(error: error.localizedDescription)))
            
        }
        
    }
    
    private func scale( _ node: inout SCNNode, by index: Float) {
        node.scale.x *= index
        node.scale.y *= index
        node.scale.z *= index
    }
    
    func addWall(to parent: SCNNode, scale: Float = 1, anchor: ARPlaneAnchor, completion: ((_ node: SCNNode) -> ())? = nil) {
        
        fetch(.post) { result in
            
            switch result {
                
            case .success(let node):
                
                var wall = node.clone()
                
                self.scale(&wall, by: scale)
                
                parent.addChildNode(wall)
                
                completion?(wall)
                
            case .failure: break    // ERROR
                
            }
            
        }
        
        
//        let extent = anchor.extent
//        let width = CGFloat(extent.x)
//        let height = CGFloat(extent.z)
//
//        let node = SCNNode(geometry: SCNPlane(width: width, height: height))
//        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//
//        node.eulerAngles.x = -.pi / 2
//        node.name = "Wall"
//        node.opacity = 0.25
//
//        return node
    }
    
}