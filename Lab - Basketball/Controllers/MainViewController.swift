//
//  MainViewController.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 30/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - @IBOutlets
    @IBOutlet weak var typesSizeBallSegmentedControl: UISegmentedControl!
    @IBOutlet weak var sizeModelButton: UIButton!
    @IBOutlet weak var startGameButton: UIButton!
    
    // MARK: - Private properties
    private let showARIdentifier = "ShowAR"
    
    private var sizesModel = ModelManager.ModelSize.allCases
    private var ballTypeSizes = ModelManager.BallTypeSize.allCases
    
    private var selectedModelSize: ModelManager.ModelSize? {
        didSet { chekChoosingOptions() }
    }
    
    private var selectedBallTypeSize: ModelManager.BallTypeSize? {
        didSet { chekChoosingOptions() }
    }
    
    // MARK: - Life cicle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set segmented control "Choosing ball type size"
        typesSizeBallSegmentedControl.replaceSegments(withTitles: ballTypeSizes.map { $0.description })
        
    }
    
    // MARK: - Private methods
    private func chekChoosingOptions() {
        
        guard selectedModelSize != nil else { return }
        guard selectedBallTypeSize != nil else { return }
        
        startGameButton.isEnabled = true
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == showARIdentifier {
            
            let augmentedRealityViewController = segue.destination as! GameViewController
            
            augmentedRealityViewController.typeBall = selectedBallTypeSize!
            augmentedRealityViewController.sizeModel = selectedModelSize!
            
        }
        
    }
    
    // MARK: - Actions
    @IBAction func actionChangeBallTypeSize(_ sender: UISegmentedControl) {
        
        selectedBallTypeSize = ballTypeSizes[sender.selectedSegmentIndex]
        
    }
    
    @IBAction func actionChooseSizeModel(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "Choose size models", message: nil, preferredStyle: .actionSheet)
        
        sizesModel.forEach { size in
            
            let action = UIAlertAction(title: size.description, style: .default) { [unowned self] _ in
                
                sender.setTitle(size.description, for: [])
                self.selectedModelSize = size
                
            }
            
            alertController.addAction(action)
            
        }
        
        present(alertController, animated: true)
        
    }
    
}
