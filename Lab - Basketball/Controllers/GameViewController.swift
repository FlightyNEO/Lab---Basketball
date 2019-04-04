//
//  GameViewController.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 28/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

// Model Basketball post - https://www.cgtrader.com/free-3d-models/exterior/exterior-public/basketball-post


import ARKit

class GameViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    // MARK: - Private properties
    private var modelManager: ModelManager!
    
    private var postIsAdded = false
    
    private var postPlacementAreaSize: CGSize? = nil
    
    private let maxBallsOnScene = 10
    private var balls = [SCNNode]()
    private var ballsCollidedWithTheFirstRing = Set<SCNNode>()
    private var failsBalls = Set<SCNNode>()
    private var throwsCount = 0
    
    private var scores: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.scoreLabel.text = String(self.scores) + " scores"
            }
        }
    }
    
    private var ballsAndScores = [(SCNNode, Int)]() {
        didSet {
            scores += self.ballsAndScores.last!.1
        }
    }
    
//    private var scoredBalls = [SCNNode]() {
//        didSet {
//            DispatchQueue.main.async {
//                self.scoreLabel.text = String(self.scoredBalls.count) + " scores"
//            }
//        }
//    }
    
    /// Distance from basketball post to three-point line
    private let threePointDistance: Float = 7.24 // meters
    
    /// Distance from basketball post to three-point line using scale
    private var threePointDistanceOfScale: Float {
        return threePointDistance * sizeModel.rawValue
    }
    
    // MARK: - Properties
    var sizeModel: ModelManager.ModelSize = .real
    var typeBall: ModelManager.BallTypeSize = .size10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        #if DEBUG
        // Show statistics such as fps and timing information
        // sceneView.showsStatistics = true
        // sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.showsStatistics = true
        // sceneView.debugOptions = [.showPhysicsShapes]
        #endif
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set the contact delegate for "scene"
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // Create model manager and prepare ball
        modelManager = ModelManager(delegate: self, ballTypeSize: typeBall, modelSize: sizeModel)
        
        // Fetch size placement area for bascketball post
        modelManager.placementAreaSizeOfPost(by: sizeModel) { postPlacementAreaSize = $0 }
        
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
        
        navigationController?.isNavigationBarHidden = false
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        #if DEBUG
        print("DEINIT")
        #endif
    }
    
}

// MARK: - Private methods
extension GameViewController {
    
    private func suitableSizeForPlacementArea(candidate: CGSize) -> Bool {
        
        guard let placementAreaSize = postPlacementAreaSize else { return false }
        
        print(placementAreaSize)
        print(candidate)
        
        guard
            (candidate.width >= placementAreaSize.width &&
            candidate.height >= placementAreaSize.height) ||
            (candidate.width >= placementAreaSize.height &&
            candidate.height >= placementAreaSize.width) else { return false }
        
        return true
        
    }
    
    private func calculateScore() -> Int? {
        
        guard let transform = sceneView.session.currentFrame?.camera.transform else { return  nil}
        let cameraPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        guard let distance = self.modelManager.distanceBetweenPost(and: cameraPosition) else { return nil }
        
        #if DEBUG
        print("Distance from post to boll - ", distance)
        print("Three-point distance line - ", threePointDistanceOfScale)
        #endif
        
        return distance >= threePointDistanceOfScale ? 3 : 1
        
    }
    
    private func calculatePowerFactor(gesture: UIPanGestureRecognizer) -> ModelManager.PowerFactor {
        
        // 1
        let velocity = gesture.velocity(in: view)
        let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
        let slideMultiplier = magnitude / 200
        
        // 2
        let frontFactor = 0.1 * slideMultiplier
        
        // 3
        let upFactor = velocity.y / 200 * -1.0
        
        #if DEBUG
        print("magnitude: \(magnitude), frontFactor: \(frontFactor), upFactor = \(upFactor)")
        #endif
        
        return (front: Float(frontFactor), up: Float(upFactor))
        
    }
    
    private func createQuitAlertViewController() {
        
        let alertController = UIAlertController(title: "Attention!", message: "Are you sure you want to quit?", preferredStyle: .alert)
        let quitAction = UIAlertAction(title: "Quit", style: .destructive) { [unowned self] _ in
            _ = self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(quitAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
        
    }
    
}

// MARK: - ARSCNViewDelegate
extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let extent = (anchor as? ARPlaneAnchor)?.extent else { return }
        
        let size = CGSize(width: CGFloat(extent.x), height: CGFloat(extent.z))
        
        // plane size check
        guard suitableSizeForPlacementArea(candidate: size) else { return }
        
        // add placement area to the scene view
        modelManager.addPlacementArea(to: node, size: size)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let extent = (anchor as? ARPlaneAnchor)?.extent else { return }
        
        let size = CGSize(width: CGFloat(extent.x), height: CGFloat(extent.z))
        
        // plane size check
        guard suitableSizeForPlacementArea(candidate: size) else { return }
        
        guard let placementArea = node.childNode(withName: "placementArea", recursively: false) else {
            
            // add placement area to the scene view
            modelManager.addPlacementArea(to: node, size: size)
            return
            
        }
        
        // update placement area
        modelManager.updatePlacementArea(placementArea, size: size)
        
    }
    
}

// MARK: - Actions
extension GameViewController {
    
    @IBAction func actionTapped(_ sender: UITapGestureRecognizer) {
        
        guard !postIsAdded else { return }
        
        // Get tap point
        let location = sender.location(in: sceneView)
        
        // Detect placement area
        guard let hitResult = sceneView.hitTest(location, options: nil).first else { return }
        guard let yRotation = sceneView.session.currentFrame?.camera.eulerAngles.y else { return }

        // add basketball post to the scene view
        modelManager.addPost(to: sceneView.scene.rootNode, size: sizeModel, hitResult: hitResult, yRotation: yRotation, floor: true) { _ in

            // Remove all placement area
            self.modelManager.removeAllPlacementAreas(from: self.sceneView.scene.rootNode)

            // Set new configuration without detection
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = []
            self.sceneView.session.run(configuration)

            self.postIsAdded = true

        }
        
    }
    
    @IBAction func actionPan(_ sender: UIPanGestureRecognizer) {
        
        guard postIsAdded else { return }
        guard let transform = sceneView.session.currentFrame?.camera.transform else { return }
        
        switch sender.state {
        
        case .ended:
            
            let powerFactor = calculatePowerFactor(gesture: sender)
            
            guard powerFactor.up > 0 else { return }
            
            // Adding and throwing ball
            modelManager.addAndThrowBall(to: sceneView.scene.rootNode, transform: transform, powerFactor: powerFactor) {
                
                self.throwsCount += 1
                
                $0.name = $0.name! + String(self.throwsCount)
                self.balls.append($0)
            }
            
            if balls.count >= maxBallsOnScene {
                
                // Removing ball
                modelManager.removeBall(balls.removeFirst())
                
            }
            
        default: break
            
        }
        
    }
    
    @IBAction func actionBack() {
        createQuitAlertViewController()
    }
    
}

// MARK: - ModelManagerDelegate
extension GameViewController: ModelManagerDelegate {
    
    func ballWillAdded(_ ball: SCNNode) {
        
        // Set position for basket ball
        guard let camera = sceneView.session.currentFrame?.camera else { return }
        
        var translation = matrix_identity_float4x4
        let diameter = modelManager.getBoundingBox(by: ball).depth
        translation.columns.3.z = Float(-diameter / 2)
        
        let transform = camera.transform * translation
        let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        ball.position = position
        
        #if DEBUG
        print("BALL DIAMETER = ", diameter)
        #endif
        
    }
    
}

// MARK: - SCNPhysicsContactDelegate
extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
        #if DEBUG
        print("did end contact", contact.nodeA.physicsBody!.categoryBitMask, contact.nodeB.physicsBody!.categoryBitMask)
        #endif
        
        if (contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.balls.rawValue &&
            contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.firstHoop.rawValue) ||
            (contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.balls.rawValue &&
                contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.firstHoop.rawValue) {
            
            let ball = contact.nodeA.name!.contains(ModelManager.NodeModel.ball.rawValue) ? contact.nodeA : contact.nodeB
            
            guard !failsBalls.contains(ball) else { return }
            
            ballsCollidedWithTheFirstRing.insert(ball)
            
            #if DEBUG
            //print("Ball collision with first helper cylinder")
            #endif
            
        }
        
        if ((contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.balls.rawValue &&
            contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.secondHoop.rawValue) ||
            (contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.balls.rawValue &&
                contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.secondHoop.rawValue)) {
            
            let ball = contact.nodeA.name!.contains(ModelManager.NodeModel.ball.rawValue) ? contact.nodeA : contact.nodeB
            
            failsBalls.insert(ball)
            
            guard !ballsCollidedWithTheFirstRing.isEmpty else { return }
            
            
            if ballsCollidedWithTheFirstRing.contains(where: { $0.name == ball.name }) &&
                !ballsAndScores.contains(where: { $0.0 == ball } ) { //.contains(ball) {
                
                // Check distance to post
                guard let score = calculateScore() else { return }
                ballsAndScores.append((ball, score))
                
                #if DEBUG
                print("Ball flew into the basket")
                #endif
                
            }
            
        }
        
    }
    
}
