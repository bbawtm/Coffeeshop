//
//  ViewController.swift
//  Coffeeshop
//
//  Created by Vadim Popov on 08.02.2023.
//

import UIKit
import MapKit


class ViewController: UIViewController, MKMapViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Stored properties
    
    private let initRegionRadius = 20000.0
    private let placesInfo = InfoContainer()
    private var selectedCityIndex: Int = 0
    private let locationManager = CLLocationManager()
    
    @IBOutlet var mapView: MKMapView!
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(cityPanel)
        setCurrentRegion()
        mapView.delegate = self
        mapView.register(CustomAnnotation.self, forAnnotationViewWithReuseIdentifier: "CustomAnnotationIdentifier")
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
        
        for place in placesInfo.contents {
            guard let coord = place.coordinates else { continue }
            let annotations = MKPointAnnotation()
            annotations.title = String(describing: place)
            annotations.coordinate = CLLocationCoordinate2D(latitude: coord.0, longitude: coord.1)
            mapView.addAnnotation(annotations)
        }
        
        NSLayoutConstraint.activate([
            cityPanel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            cityPanel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cityPanel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cityPanel.heightAnchor.constraint(equalToConstant: 45),
        ])
    }
    
    private func setCurrentRegion() {
        guard placesInfo.cities.count > selectedCityIndex && selectedCityIndex >= 0 else {
            fatalError("no city for current index")
        }
        mapView.setRegion(MKCoordinateRegion(center: placesInfo.cities[selectedCityIndex].location, latitudinalMeters: initRegionRadius, longitudinalMeters: initRegionRadius), animated: true)
    }
    
    // MARK: - MapView functions
    
    private lazy var sheetViewController = {
        let sheetStoryboard = UIStoryboard.init(name: "BottomSheetSubscreen", bundle: Bundle.main)
        let sheetViewController = sheetStoryboard.instantiateInitialViewController() as! BottomSheetViewController
        return sheetViewController
    }()
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.coordinate.latitude == mapView.userLocation.coordinate.latitude &&
            annotation.coordinate.longitude == mapView.userLocation.coordinate.longitude
        {
            return nil
        }
        return mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotationIdentifier")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let view = view as? CustomAnnotation, let annotation = view.annotation else { return }
        view.setSelectedStyle()
        
        sheetViewController.setPlaceAddress(annotation.title!!)
        sheetViewController.dismissClosure = {
            self.mapView.deselectAnnotation(annotation, animated: true)
        }
        sheetViewController.showRouteClosure = {
            self.drawRoute(toCoordinate: annotation.coordinate)
        }

        if let sheet = sheetViewController.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                return context.maximumDetentValue * 0.33
            })]
            sheet.prefersGrabberVisible = true
        }
        self.present(sheetViewController, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let view = view as? CustomAnnotation else { return }
        view.setDeselectedStyle()
    }
    
    // MARK: draw a route
    
    private func drawRoute(toCoordinate destination: CLLocationCoordinate2D) {
        let req = MKDirections.Request()
        req.source = MKMapItem.forCurrentLocation()
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        req.requestsAlternateRoutes = true
        req.transportType = .walking
        
        let directions = MKDirections(request: req)
        directions.calculate { res, err in
            guard err == nil else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Маршрут недоступен", message: err?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self.sheetViewController.present(alert, animated: true)
                }
                return
            }
            if let routes = res?.routes, routes.count > 0 {
                let quickestRoute = routes.sorted { $0.expectedTravelTime < $1.expectedTravelTime }[0]
                self.mapView.removeOverlays(self.mapView.overlays)
                self.plotPolyline(route: quickestRoute)
            } else {
                fatalError("no routes found")
            }
        }
    }
    
    private func plotPolyline(route: MKRoute) {
        mapView.addOverlay(route.polyline)
        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 100.0, left: 100.0, bottom: 100.0, right: 100.0),
            animated: true
        )
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if (overlay is MKPolyline) {
            polylineRenderer.strokeColor = .systemGreen
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }
    
    // MARK: - Picker functions
    
    private var nextSelectedRow: Int = 0
    
    private lazy var cityPanel: UITextField = {
        let textfield = UITextField()
        
        textfield.text = "Санкт-Петербург"
        textfield.textColor = .darkGray
        textfield.tintColor = .clear
        textfield.backgroundColor = .white
        textfield.layer.cornerRadius = 22.5
        
        textfield.inputView = self.cityPicker
        textfield.inputAccessoryView = self.cityPickerToolBar
        
        textfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        textfield.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        textfield.leftViewMode = .always
        textfield.rightViewMode = .always
        
        textfield.layer.shadowOpacity = 0.2
        textfield.layer.shadowRadius = 5.0
        textfield.layer.shadowOffset = CGSize.zero
        textfield.layer.shadowColor = UIColor.gray.cgColor
        
        textfield.translatesAutoresizingMaskIntoConstraints = false
        return textfield
    }()
    
    private lazy var cityPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.backgroundColor = .white
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    private lazy var cityPickerToolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: UIBarButtonItem.Style.done,
            target: self,
            action: #selector(donePicker)
        )
        toolBar.setItems([.flexibleSpace(), doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        return toolBar
    }()
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        self.placesInfo.cities.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        self.placesInfo.cities[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.nextSelectedRow = row
    }
    
    @objc private func donePicker() {
        cityPanel.text = placesInfo.cities[nextSelectedRow].name
        selectedCityIndex = nextSelectedRow
        setCurrentRegion()
        cityPanel.resignFirstResponder()
    }
    
}

