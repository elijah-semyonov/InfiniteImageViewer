//
//  ViewController.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import UIKit

class ViewController: UIViewController {
    override func loadView() {
        guard let infiniteView = InfiniteView(tileDataProvider: MockTileDataProvider()) else {
            assertionFailure()
            view = UIView()
            return
        }
        
        view = infiniteView
    }
}

