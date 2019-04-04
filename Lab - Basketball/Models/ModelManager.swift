//
//  ModelManager.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 28/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

import ARKit

struct CollisionCategory: OptionSet {
    let rawValue: Int
    
    static let balls  = CollisionCategory(rawValue: 1 << 0) // 00...0001
    static let firstHoop = CollisionCategory(rawValue: 1 << 1) // 00..0010
    static let secondHoop = CollisionCategory(rawValue: 1 << 2) // 00..0100
    static let floor = CollisionCategory(rawValue: 1 << 3) // 00..1000
    static let post = CollisionCategory(rawValue: 1 << 4) // 00..0001 ...
    
}

protocol ModelManagerDelegate: class {
    
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

// MARK: -
class ModelManager {
    
    // MARK: Private properties
    private var basketballPost: SCNNode?
    private var preparedBall: SCNNode?
    private var currentTypeSize: BallTypeSize?
    
    // MARK: - Properties
    weak var delegate: ModelManagerDelegate?
    
    var ball: SCNNode? {
        return preparedBall
    }
    
    var typeSize: BallTypeSize? {
        return currentTypeSize
    }
    
    // MARK: - Initialization
    init(delegate: ModelManagerDelegate? = nil) {
        self.delegate = delegate
    }
    
    convenience init(delegate: ModelManagerDelegate?, ballTypeSize: BallTypeSize, modelSize: ModelSize) {
        self.init(delegate: delegate)
        
        prepareBall(typeSize: ballTypeSize, size: modelSize)
    }
    
}

// MARK: -
extension ModelManager {
    
    typealias PowerFactor = (front: Float, up: Float)
    
    enum NodeModel: String {
        
        case post = "BasketballPost"
        case ball = "Basketball"
        case floor = "floor"
        
        case cylinder1
        case cylinder2
        
        static var cylinders: [NodeModel] {
            return [.cylinder1, .cylinder2]
        }
        
        fileprivate var sceneName: String {
            
            switch self {
                
            case .post, .floor, .cylinder1, .cylinder2: return "art.scnassets/Basketball_Post/Basketball_Post.scn"
            case .ball: return "art.scnassets/Basketball_Post/Basket ball/basketball.dae"
                
            }
            
        }
        
    }
    
    /**
     Model size relative to the real world
     */
    enum ModelSize: Float, CaseIterable, CustomStringConvertible {
        case real = 1           // 4 meters
        case half = 0.5         // 2 meters
        case third = 0.3333     // 1.(3) meters
        case quarter = 0.25     // 1 meters
        case quaver = 0.125     // 0.5 meters
        
        var description: String {
            
            switch self {
                
            case .real: return "Real size"
            case .half: return "Half size"
            case .third: return "Third size"
            case .quarter: return "Quarter size"
            case .quaver: return "Quaver size"
                
            }
            
        }
        
    }
    
    /**
     Ball size relative to the real world
     */
    enum BallTypeSize: Float, CaseIterable, CustomStringConvertible {
        
        case size10 = 1         // 34.5" 0.279m
        case size7 = 0.855      // 29.5" 0.239m
        case size6 = 0.826      // 28.5" 0.231m
        case size5 = 0.797      // 27.5" 0.222m
        case size3 = 0.739      // 25.5" 0.206m
        
        var description: String {
            
            switch self {
                
            case .size3: return #"25,5""#
            case .size5: return #"27,5""#
            case .size6: return #"28,5""#
            case .size7: return #"29,5""#
            case .size10: return #"34,5""#
                
            }
            
        }
        
        var mass: CGFloat {
            
            switch self {
                
            case .size3: return 0.315
            case .size5: return 0.485
            case .size6: return 0.520
            case .size7: return 0.620
            case .size10: return 0.850
                
            }
            
        }
        
    }
    
    // MARK: - Errors
    enum NodeManagerError: Error {
        case fetchError(error: String)
    }
    
}

// MARK: - Private methods
extension ModelManager {
    
    // MARK: ... create node
    private func nodeFrom(_ sceneFile: String?) throws -> SCNNode {
        
        guard
            let sceneFile = sceneFile,
            let sceneNode = SCNScene(named: sceneFile)?.rootNode else {
                
                throw NodeManagerError.fetchError(error: "Not found node for this name")
                
        }
        
        return sceneNode
    }
    
    /// Fetching SCNNode from SCNScene
    ///
    /// - Parameters:
    ///   - model: type of model
    ///   - completion: return SCNNode if success, Error if failure
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
    private func createPhysicsBodyForCylinder(_ node: SCNNode) -> SCNPhysicsBody {
        
        let options: [SCNPhysicsShape.Option : Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull]
        let shape = SCNPhysicsShape(node: node, options: options)
        let body = SCNPhysicsBody(type: .static, shape: shape)
        
        body.isAffectedByGravity = false
        body.contactTestBitMask = CollisionCategory.balls.rawValue
        body.collisionBitMask = 0
        
        return body
    }
    
    private func createPhysicsBodyForFloor(_ floor: SCNNode) -> SCNPhysicsBody {
        
        let options: [SCNPhysicsShape.Option : Any] = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox]
        let shape = SCNPhysicsShape(node: floor, options: options)
        let body = SCNPhysicsBody(type: .static, shape: shape)
        
        body.isAffectedByGravity = false
        body.categoryBitMask = CollisionCategory.floor.rawValue
        body.collisionBitMask = CollisionCategory.balls.rawValue
        
        return body
    }
    
    private func createPhysicsBodyForPost(_ post: SCNNode) -> SCNPhysicsBody {
        
        let options: [SCNPhysicsShape.Option : Any] = [
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron,
            SCNPhysicsShape.Option.collisionMargin: 0.001]
        let shape = SCNPhysicsShape(node: post, options: options)
        let body = SCNPhysicsBody(type: .static, shape: shape)
        
        body.isAffectedByGravity = false
        body.categoryBitMask = CollisionCategory.post.rawValue
        body.collisionBitMask = CollisionCategory.balls.rawValue
        
        return body
    }
    
    private func createPhysicsBodyForBall(_ ball: SCNNode, typeSyze: BallTypeSize, transform: simd_float4x4, powerFactor: PowerFactor) -> SCNPhysicsBody {
        
        let options: [SCNPhysicsShape.Option : Any] = [SCNPhysicsShape.Option.collisionMargin: 0.001]
        let shape = SCNPhysicsShape(node: ball, options: options)
        let power = 3 * powerFactor.front
        let cameraTransform = SCNMatrix4(transform)
        let forceDirection = SCNVector3(-cameraTransform.m31 * power,
                                        -cameraTransform.m32 * powerFactor.up,
                                        -cameraTransform.m33 * power)
        let torqueDirection = SCNVector4Make(randFloat(-1,1), randFloat(-1,1), randFloat(-1,1), randFloat(-1,1))
        let body = SCNPhysicsBody(type: .dynamic, shape: shape)
        
        body.isAffectedByGravity = true
        body.applyTorque(torqueDirection, asImpulse: true)
        body.applyForce(forceDirection, asImpulse: true)
        body.mass = typeSyze.mass
        body.friction = 2
        
        // bit mask
        body.categoryBitMask = CollisionCategory.balls.rawValue
        body.contactTestBitMask = CollisionCategory.firstHoop.rawValue | CollisionCategory.secondHoop.rawValue
        body.collisionBitMask = CollisionCategory.post.rawValue | CollisionCategory.floor.rawValue | CollisionCategory.balls.rawValue
        
        #if DEBUG
        print("BALL POWER - ", powerFactor)
        #endif
        
        return body
    }
    
    // MARK: ... adding node
    private func addFloor(to parent: SCNNode, size: ModelSize = .real, position: SCNVector3) {
        
        fetch(.floor) { resultFloor in
            
            guard case let .success(node) = resultFloor else { return }
            
            var floor = node
            self.scale(&floor, by: size.rawValue)
            floor.position = position
            floor.physicsBody = createPhysicsBodyForFloor(floor)
            
            parent.addChildNode(floor)
            
        }
        
    }
    
    private func addHelperCylinders(for post: SCNNode) {
        
        NodeModel.cylinders.enumerated().forEach { index, cylinder in
            
            
            let helperCylinder = post.childNode(withName: cylinder.rawValue, recursively: true)
            var shape = helperCylinder?.copy() as! SCNNode
            self.scale(&shape, by: post.scale.x)
            
            helperCylinder?.physicsBody = createPhysicsBodyForCylinder(shape)
            
            if index == 0 {
                helperCylinder?.physicsBody?.categoryBitMask = CollisionCategory.firstHoop.rawValue
            } else {
                helperCylinder?.physicsBody?.categoryBitMask = CollisionCategory.secondHoop.rawValue
            }
            
        }
        
    }
    
    private func addPost(to parent: SCNNode, size: ModelSize = .real, position: SCNVector3, yRotation: Float, floor: Bool = false, completion: ((_ post: SCNNode) -> ())? = nil) {
        
        fetch(.post) { result in
            
            switch result {
                
            case .success(var post):
                
                // Scaling
                scale(&post, by: size.rawValue)
                
                // Position and orientation
                post.position = position
                post.eulerAngles = SCNVector3(0, yRotation, 0)
                
                // Physics
                post.physicsBody = createPhysicsBodyForPost(post)
                
                delegate?.postWillAdded()
                
                // add helper cylinders
                addHelperCylinders(for: post)
                
                // add floor
                if floor {
                    addFloor(to: parent, size: size, position: position)
                }
                
                parent.addChildNode(post)
                
                delegate?.postDidAdded()
                
                basketballPost = post
                
                completion?(post)
                
            case .failure: break    // ERROR
                
            }
            
        }
        
    }
    
}

// MARK: - Public methods
extension ModelManager {
    
    func distanceBetweenPost(and position: SCNVector3) -> Float? {
        
        guard let post = basketballPost else { return nil }
        
        let positionOne = SCNVector3ToGLKVector3(post.presentation.worldPosition)
        let positionTwo = SCNVector3ToGLKVector3(position)
        
        return GLKVector3Distance(positionOne, positionTwo)
    }
    
//    func distanceFromPost(to node: SCNNode) -> Float? {
//        
//        guard let post = basketballPost else { return nil }
//        
//        let node1Position = SCNVector3ToGLKVector3(post.presentation.worldPosition)
//        let node2Position = SCNVector3ToGLKVector3(node.presentation.worldPosition)
//        
//        return GLKVector3Distance(node1Position, node2Position)
//        
//    }
    
    func getCameraTransform(for sceneView: ARSCNView) -> MDLTransform? {
        guard let transform = sceneView.session.currentFrame?.camera.transform else { return nil }
        return MDLTransform(matrix: transform)
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
    
    // MARK: ... preparing
    
    /**
     Подготавливает мяч для будущих добавлений
     */
    func prepareBall(typeSize: BallTypeSize, size: ModelSize = .real, completion: ((_ ball: SCNNode) -> ())? = nil) {
        
        fetch(.ball) { result in
            
            switch result {
                
            case .success(let node):
                
                var ball = node
                
                // Scaling
                self.scale(&ball, by: typeSize.rawValue * size.rawValue)
                
                currentTypeSize = typeSize
                
                self.preparedBall = ball
                
                completion?(ball)
                
            case .failure: break    // ERROR
                
            }
            
        }
        
    }
    
    // MARK: ... adding
    
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
     Создает мяч из настроек подготовленного мяча
     */
    func addAndThrowBall(to parent: SCNNode, transform: simd_float4x4, powerFactor: PowerFactor = (front: 1.0, up: 1.0), completion: ((_ post: SCNNode) -> ())? = nil) {
        
        guard let ball = preparedBall?.clone() else { return }
        guard let typeSize = currentTypeSize else { return }
        
        // add position
        let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        ball.position = position
        
        // Physics
        ball.physicsBody = createPhysicsBodyForBall(ball, typeSyze: typeSize, transform: transform, powerFactor: powerFactor)
//        let forceDirection = createForceDirection(to: ball, transform: transform, powerFactor: powerFactor)
//        ball.physicsBody?.applyForce(forceDirection, asImpulse: true)
        
        delegate?.ballWillAdded(ball)
        
        parent.addChildNode(ball)
        
        delegate?.ballDidAdded(ball)
        
        completion?(ball)
        
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
    func addBall(typeSize: BallTypeSize, to parent: SCNNode, size: ModelSize = .real, transform: simd_float4x4, powerFactor: PowerFactor = (front: 1.0, up: 1.0), completion: ((_ ball: SCNNode) -> ())? = nil) {
        
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
                ball.physicsBody = createPhysicsBodyForBall(ball, typeSyze: typeSize, transform: transform, powerFactor: powerFactor)
                
                delegate?.ballWillAdded(ball)
                
                parent.addChildNode(ball)
                
                delegate?.ballDidAdded(ball)
                
                completion?(ball)
                
            case .failure: break    // ERROR
                
            }
            
        }
        
    }
    
    // MARK: ... updating
    func updatePlacementArea(_ placementArea: SCNNode, size: CGSize, completion: ((_ placementArea: SCNNode) -> ())? = nil) {
        
        delegate?.placementAreaWillUpdated()
        
        (placementArea.geometry as? SCNPlane)?.width = size.width
        (placementArea.geometry as? SCNPlane)?.height = size.height
        
        delegate?.placementAreaDidUpdated()
        
        completion?(placementArea)
        
    }
    
    // MARK: ... removing
    func removeAllPlacementAreas(from node: SCNNode) {
        
        node.enumerateChildNodes { node, _ in
            if node.name == "placementArea" {
                node.removeFromParentNode()
            }
        }
        
    }
    
    func removeBall(_ ball: SCNNode) {
        
        ball.removeFromParentNode()
        
    }
    
    // TODO: -
    // TODO: 1 Removing balls
    // TODO: 2 Scoring
    
}
