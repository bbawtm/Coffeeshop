//
//  ViewController.swift
//  Coffeeshop
//
//  Created by Vadim Popov on 08.02.2023.
//

import UIKit
import MapKit


class ViewController: UIViewController, MKMapViewDelegate {
    
    private let initRegionRadius = 20000.0
    
    @IBOutlet var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placesInfo = InfoContainer()
        print(placesInfo.contents)
        
        
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 59.938955, longitude: 30.315644), latitudinalMeters: initRegionRadius, longitudinalMeters: initRegionRadius), animated: true)
        mapView.delegate = self
        
        for place in placesInfo.contents {
            guard let coord = place.coordinates else { continue }
            let annotations = MKPointAnnotation()
            annotations.title = String(describing: place)
            annotations.coordinate = CLLocationCoordinate2D(latitude: coord.0, longitude: coord.1)
            mapView.addAnnotation(annotations)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        
        let sheetStoryboard = UIStoryboard.init(name: "BottomSheetSubscreen", bundle: Bundle.main)
        let sheetViewController = sheetStoryboard.instantiateInitialViewController() as! BottomSheetViewController
        sheetViewController.setPlaceAddress(annotation.title!!)
        sheetViewController.dismissClosure = {
            self.mapView.deselectAnnotation(view.annotation, animated: true)
        }

        if let sheet = sheetViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(sheetViewController, animated: true)
    }
    
    
    
}

