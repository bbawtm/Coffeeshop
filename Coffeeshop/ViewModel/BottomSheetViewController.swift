//
//  BottomSheetViewController.swift
//  Coffeeshop
//
//  Created by Vadim Popov on 08.02.2023.
//

import UIKit


class BottomSheetViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet var placeAddress: UILabel!
    
    public var providedAddress: String?
    public var dismissClosure: (() -> Void)?
    public var showRouteClosure: (() -> Void)?
    
    override func viewDidLoad() {
        placeAddress.text = providedAddress
        self.presentationController?.delegate = self
    }
    
    public func setPlaceAddress(_ addr: String) {
        providedAddress = addr
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.dismissClosure?()
    }
    
    @IBAction func showRoute(_ sender: UIButton) {
        self.showRouteClosure?()
    }
    
}
