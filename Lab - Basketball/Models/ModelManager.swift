//
//  ModelManager.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 28/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

import ARKit

protocol ModelManagerDelegate {
    
    func postWillAdded()
    func placementAreaWillAdded()
    func placementAreaWillUpdated()
    func ballWillAdded(_ ball: SCNNode)
    
    func postDidAdded()
    func placementAreaDidAdded()
    func placementAreaDidUpdated()
    func ballDidAdded(_ ball: SCNNode)
    
}

extension ModelManagerDelegate {
    func postWillAdded() { print(#function) }
    func placementAreaWillAdded() { print(#function) }
    func placementAreaWillUpdated() { print(#function) }
    func ballWillAdded(_ ball: SCNNode) { print(#function) }
    func postDidAdded() { print(#function) }
    func placementAreaDidAdded() { print(#function) }
    func placementAreaDidUpdated() { print(#function) }
    func ballDidAdded(_ ball: SCNNode) { print(#function) }
}

struct ModelManager {
    
    // MARK: - Properties
    
    typealias PowerFactor = (front: Float, up: Float)
    
    enum NodeModel: String {
        
        case post = "BasketballPost"
        case ball2 = "Ball"
        case ball = "Basketball"
        case floor = "floor"
        
        fileprivate var sceneName: String {
            
            switch self {
                
            case .post: return "art.scnassets/Basketball_Post/Basketball_Post.scn"
            case .ball2: return "art.scnassets/Basketball_Post/Basket ball/BASEKT_Ball-2.scn"
            case .ball: return "art.scnassets/Basketball_Post/Basket ball/basketball.dae"
            case .floor: return "art.scnassets/Basketball_Post/Basketball_Post.scn"
                
            }
            
        }
        
    }
    
    /**
     Model size relative to the real world
     */
    enum ModelSize: Float {
        case real = 1           // 4 meters
        case half = 0.5         // 2 meters
        case third = 0.3333     // 1.(3) meters
        case quarter = 0.25     // 1 meters
        case quaver = 0.125     // 0.5 meters
    }
    
    /**
     Ball size relative to the real world
     */
    enum BallTypeSize: Float {
        case size10 = 1         // 34.5" 0.279m
        case size7 = 0.855      // 29.5" 0.239m
        case size6 = 0.826      // 28.5" 0.231m
        case size5 = 0.797      // 27.5" 0.222m
        case size3 = 0.739      // 25.5" 0.206m
    }
    
    
    var delegate: ModelManagerDelegate?
    
    // MARK: - Initialization
    private init() {}
    static var manager: ModelManager { return ModelManager() }
    
    // MARK - Errors
    enum NodeManagerError: Error {
        case fetchError(error: String)
    }
    
    // MARK: - Private methods
    // MARK: ... create node
    private func nodeFrom(_ sceneFile: String?) throws -> SCNNode {
        
        guard
            let sceneFile = sceneFile,
            let sceneNode = SCNScene(named: sceneFile)?.rootNode else {
                
                throw NodeManagerError.fetchError(error: "Not found node for this name")
                
        }
        
        return sceneNode
    }
    
    private func fetch(_ model: NodeModel, completion: (Result<SCNNode, NodeManagerError>) -> ()) {
        
        do {
            
            let sceneNode = try nodeFrom(model.sceneName)
            
            guard let node = sceneNode.childNode(withName: model.rawValue, recursively: true) else {
                
                completion(.failure(.fetchError(error: "Not found node for this name")))
                return
                
            }
            
            completion(.success(node))
            
        } catch (let error) {
            
            completion(.failure(.fetchError(error: error.localizedDescription)))
            
        }
        
    }
    
    // MARK: ... transform
    private func scale( _ node: inout SCNNode, by index: Float) {
        node.scale.x *= index
        node.scale.y *= index
        node.scale.z *= index
    }
    
    // MARK: ... physics
    private func createStaticPhysicsBodyFor(_ node: SCNNode) -> SCNPhysicsBody {
        
        let options: [SCNPhysicsShape.Option : Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
        let shape = SCNPhysicsShape(node: node, options: options)
        
        return SCNPhysicsBody(type: .static, shape: shape)
        
    }
    
    private func createPhysicsBodyForFloor(_ floor: SCNNode) -> SCNPhysicsBody {
        return createStaticPhysicsBodyFor(floor)
    }
    
    private func createPhysicsBodyForPost(_ post: SCNNode) -> SCNPhysicsBody {
        return createStaticPhysicsBodyFor(post)
    }
    
    private func createPhysicsBodyForBall(_ ball: SCNNode, transform: simd_float4x4, powerFactor: PowerFactor) -> SCNPhysicsBody {
        
        let options: [SCNPhysicsShape.Option : Any] = [SCNPhysicsShape.Option.collisionMargin: 0.01]
        let shape = SCNPhysicsShape(node: ball, options:options)
        let power = 3 * powerFactor.front
        let cameraTransform = SCNMatrix4(transform)
        let forceDirection = SCNVector3(-cameraTransform.m31 * power,
                                        -cameraTransform.m32 * powerFactor.up,
                                        -cameraTransform.m33 * power)
        let body = SCNPhysicsBody(type: .dynamic, shape: shape)
        
//        let gravityField = SCNPhysicsField.radialGravity()
//        gravityField.strength = 75
//        ball.physicsField = gravityField
        
        
        body.applyForce(forceDirection, asImpulse: true)
        
        #if DEBUG
        print("BALL POWER - ", power)
        #endif
        
        return body
        
    }
    
    // MARK: ... adding node
    private func addPost(to parent: SCNNode, size: ModelSize = .real, position: SCNVector3, yRotation: Float, floor: Bool = false, completion: ((_ post: SCNNode) -> ())? = nil) {
        
        fetch(.post) { result in
            
            switch result {
                
            case .success(var post):
                
                // Scaling
                self.scale(&post, by: size.rawValue)
                
                // Position and orientation
                post.position = position
                post.eulerAngles = SCNVector3(0, yRotation, 0)
                
                // Physics
                post.physicsBody = createPhysicsBodyForPost(post)
                
                delegate?.postWillAdded()
                
                // add floor
                if floor {
                    
                    fetch(.floor) { resultFloor in
                        
                        guard case let .success(node) = resultFloor else { return }
                        
                        var floor = node
                        self.scale(&floor, by: size.rawValue)
                        floor.position = position
                        floor.physicsBody = createPhysicsBodyForPost(floor)
                        
                        parent.addChildNode(floor)
                        
                    }
                    
                }
                
                parent.addChildNode(post)
                
                delegate?.postDidAdded()
                
                completion?(post)
                
            case .failure: break    // ERROR
                
            }
            
        }
        
    }
    
    // MARK: - public methods
    
    func getCameraTransform(for sceneView: ARSCNView) -> MDLTransform? {
        guard let transform = sceneView.session.currentFrame?.camera.transform else { return nil }
        return MDLTransform(matrix: transform)
    }
    
    func removeAllPlacementAreas(from node: SCNNode) {
        
        node.enumerateChildNodes { node, _ in
            if node.name == "placementArea" {
                node.removeFromParentNode()
            }
        }
        
    }
    
    func getBoundingBox(by node: SCNNode) -> (width: CGFloat, height: CGFloat, depth: CGFloat) {
        
        var box: (width: CGFloat, height: CGFloat, depth: CGFloat)
        
        let boundingBox = node.boundingBox
        
        box.width = CGFloat(boundingBox.max.x - boundingBox.min.x) * CGFloat(node.scale.x)
        box.height = CGFloat(boundingBox.max.y - boundingBox.min.y) * CGFloat(node.scale.y)
        box.depth = CGFloat(boundingBox.max.z - boundingBox.min.z) * CGFloat(node.scale.z)
        
        return box
        
    }
    
    /**
     Fetch placement area size for post by size in real world
     
     - parameters:
        - modelSize: the size of the post in the real world. Default is "Real"
        - completion: return "placement area size".
     */
    func placementAreaSizeOfPost(by modelSize: ModelSize, completion: (CGSize?) -> ()) {
        
        fetch(.post) { resultNode in
            
            let resultDimensions = resultNode.map { (boundingBox: $0.boundingBox, scale: $0.scale) }
            
            guard case let .success(dimensions) = resultDimensions else { completion(nil); return }
            
            var boundingBox: (width: CGFloat, height: CGFloat)
            boundingBox.width = CGFloat((dimensions.boundingBox.max.x * dimensions.scale.x) - (dimensions.boundingBox.min.x * dimensions.scale.x)) * CGFloat(modelSize.rawValue)
            boundingBox.height = CGFloat((dimensions.boundingBox.max.z * dimensions.scale.z) - (dimensions.boundingBox.min.z * dimensions.scale.z)) * CGFloat(modelSize.rawValue)
            
            completion(CGSize(width: boundingBox.width, height: boundingBox.height))
            
        }
        
    }
    
    func addPlacementArea(to parent: SCNNode, size: CGSize, completion: ((_ placementArea: SCNNode) -> ())? = nil) {
        
        let placementAreaNode = SCNNode(geometry: SCNPlane(width: size.width, height: size.height))
        placementAreaNode.geometry?.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.060786888, green: 0.223592639, blue: 0.8447286487, alpha: 0.5)
        placementAreaNode.eulerAngles.x = Float(-90.radians)
        placementAreaNode.name = "placementArea"
        
        delegate?.placementAreaWillAdded()
        
        parent.addChildNode(placementAreaNode)
        
        delegate?.placementAreaDidAdded()
        
        completion?(placementAreaNode)
        
    }
    
    func updatePlacementArea(_ placementArea: SCNNode, size: CGSize, completion: ((_ placementArea: SCNNode) -> ())? = nil) {
        
        delegate?.placementAreaWillUpdated()
        
        (placementArea.geometry as? SCNPlane)?.width = size.width
        (placementArea.geometry as? SCNPlane)?.height = size.height
        
        delegate?.placementAreaDidUpdated()
        
        completion?(placementArea)
        
    }
    
    /**
     Add basketball post to a node
     
     - parameters:
        - parent: node where post is added
        - size: the size of the post in the real world. Default is "Real"
        - hitTest:
        - yRotation: Y-axis rotation
        - completion: return "post node". Default is "nil"
     */
    func addPost(to parent: SCNNode, size: ModelSize = .real, hitResult: ARHitTestResult, yRotation: Float, floor: Bool = false, completion: ((_ post: SCNNode) -> ())? = nil) {
        let position = SCNVector3(hitResult.worldTransform.columns.3.x,
                                  hitResult.worldTransform.columns.3.y,
                                  hitResult.worldTransform.columns.3.z)
        addPost(to: parent, size: size, position: position, yRotation: yRotation, floor: floor, completion: completion)
    }
    
    /**
     Add basketball post to a node
     
     - parameters:
         - parent: node where post is added
         - size: the size of the post in the real world. Default is "Real"
         - hitTest:
         - yRotation: Y-axis rotation
         - completion: return "post node". Default is "nil"
     */
    func addPost(to parent: SCNNode, size: ModelSize = .real, hitResult: SCNHitTestResult, yRotation: Float, floor: Bool = false, completion: ((_ post: SCNNode) -> ())? = nil) {
        let position = SCNVector3(hitResult.worldCoordinates.x,
                                  hitResult.worldCoordinates.y,
                                  hitResult.worldCoordinates.z)
        addPost(to: parent, size: size, position: position, yRotation: yRotation, floor: floor, completion: completion)
    }
    
    /**
     Add basket ball to a node
     
     - parameters:
         - typeSize: type size of the ball
         - parent: node where ball is added
         - size: the size of the ball in the real world. Default is "Real"
         - transform: transform ball
         - completion: return "ball node". Default is "nil"
     */
    func addBall(typeSize: BallTypeSize, to parent: SCNNode, size: ModelSize = .real, transform: simd_float4x4, powerFactor: PowerFactor = (front: 1.0, up: 1.0), completion: ((_ post: SCNNode) -> ())? = nil) {
//        let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
//        addBall(typeSize: typeSize, to: parent, size: size, position: position, completion: completion)
        
        fetch(.ball) { result in
            
            switch result {
                
            case .success(let node):
                
                var ball = node.clone()
                
                // Scaling
                self.scale(&ball, by: typeSize.rawValue * size.rawValue)
                
                // add position
                let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                ball.position = position
                
                // Physics
                ball.physicsBody = createPhysicsBodyForBall(ball, transform: transform, powerFactor: powerFactor)
                
                delegate?.ballWillAdded(ball)
                
                parent.addChildNode(ball)
                
                delegate?.ballDidAdded(ball)
                
                completion?(ball)
                
            case .failure: break    // ERROR
                
            }
            
        }
    }
    
}
