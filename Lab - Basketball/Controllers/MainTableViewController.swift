//
//  MainTableViewController.swift
//  Lab - Basketball
//
//  Created by Arkadiy Grigoryanc on 30/03/2019.
//  Copyright © 2019 Arkadiy Grigoryanc. All rights reserved.
//

import UIKit

class MainTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    // MARK: - Private properties
    private let modelCellIdentifier = "ModelCell"
    private let showARIdentifier = "ShowAR"
    private let unwindToMainIdentifier = "UnwindToMain"
    
    private var types = ModelManager.BallTypeSize.allCases
    
    // MARK: - Properties
    var selectedType: ModelManager.BallTypeSize = .size10
    
    // MARK: - Life cicles
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: modelCellIdentifier, for: indexPath)
        cell.textLabel?.text = types[indexPath.row].description
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        selectedType = types[indexPath.row]
        return indexPath
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == showARIdentifier {
            
            let augmentedRealityViewController = segue.destination as! ViewController
            augmentedRealityViewController.typeBall = selectedType
            
        }
        
    }
    
}
