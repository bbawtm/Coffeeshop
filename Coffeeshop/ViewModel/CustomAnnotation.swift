//
//  CustomAnnotation.swift
//  Coffeeshop
//
//  Created by Vadim Popov on 11.02.2023.
//

import UIKit
import MapKit


class CustomAnnotation: MKAnnotationView {
    
    private let transformationScale = 1.3
    private let logoImageView = UIImageView(image: UIImage(named: "AnnotationImage"))
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        frame = logoImageView.frame.applying(CGAffineTransform(scaleX: 0.27, y: 0.27))
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
//        centerOffset = CGPoint(x: -frame.size.height / transformationScale, y: -frame.size.height / 2)
        
        addSubview(logoImageView)
        logoImageView.frame = bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setSelectedStyle() {
        frame = CGRect(
            origin: frame.origin,
            size: frame.size.applying(CGAffineTransform(scaleX: transformationScale, y: transformationScale))
        )
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        logoImageView.frame = bounds
//        centerOffset = CGPoint(x: -frame.size.width / 2, y: -frame.size.height / 2)
//        centerOffset = CGPoint(x: -frame.size.height / transformationScale, y: -frame.size.height / 2)
//        centerOffset = centerOffset.applying(CGAffineTransform(scaleX: -transformationScale, y: transformationScale))

        
    }
    
    public func setDeselectedStyle() {
        frame = CGRect(
            origin: frame.origin,
            size: frame.size.applying(CGAffineTransform(scaleX: 1.0/transformationScale, y: 1.0/transformationScale))
        )
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        logoImageView.frame = bounds
//        frame = frame.applying(CGAffineTransform(scaleX: 1.0/transformationScale, y: 1.0/transformationScale))
//        logoImageView.frame = frame
//        centerOffset = CGPoint(x: -frame.size.width / 2, y: -frame.size.height / 2)
//        centerOffset = CGPoint(x: -frame.size.height * transformationScale, y: -frame.size.height / 2)

//        centerOffset = centerOffset.applying(CGAffineTransform(scaleX: 1.0/transformationScale, y: 1.0/transformationScale))
    }
    
}
