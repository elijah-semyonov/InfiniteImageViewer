//
//  ViewController.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import UIKit

class ViewController: UIViewController {
    override func loadView() {
        view = InfiniteImageView(tileDataProvider: TileDataProvider())
    }
}
