//
//  InfoContainer.swift
//  Coffeeshop
//
//  Created by Vadim Popov on 08.02.2023.
//

import UIKit
import MapKit


class InfoContainer {
    
    // MARK: - One item
    
    public class Place: CustomStringConvertible {
        public var city: String?
        public var address: String?
        public var coordinates: (Double, Double)?
        
        public var description: String { "\(city ?? "nil"),\n\(address?.capitalized ?? "nil")" }
    
        public var isValid: Bool { !(city?.isEmpty ?? true) && !(address?.isEmpty ?? true) && coordinates != nil }
    }
    
    public class City {
        public let name: String
        public var latitude: Double = 59.9366713
        public var longitude: Double = 30.3150267
        
        public var location: CLLocationCoordinate2D {
            get {
                .init(latitude: latitude, longitude: longitude)
            }
            set {
                self.latitude = newValue.latitude
                self.longitude = newValue.longitude
            }
        }
        
        public init(name: String) {
            self.name = name
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = name
            let search = MKLocalSearch(request: request)
            search.start { res, err in
                if let coordinate = res?.mapItems[0].placemark.coordinate {
                    self.location = coordinate
                } else {
                    print("Cannot find location")
                }
            }
        }
    }
    
    // MARK: - XML Parser
    
    public class Parser: NSObject, XMLParserDelegate {
        
        public var parsedArray: [Place] = []
        private var currentPlace: Place?
        private var currentPlaceItem: String?
        private var currentBuffer: String?
        
        public func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String : String] = [:]
        ) {
            currentPlaceItem = elementName
            currentBuffer = ""
            if elementName == "Place" {
                currentPlace = Place()
            }
        }
        
        public func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentBuffer? += string
        }
        
        public func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            if elementName == "Place" {
                guard let currentPlace, currentPlace.isValid else {
                    print("{\(currentPlace?.city ?? "nil"), \(currentPlace?.address ?? "nil"), \(String(describing: currentPlace?.coordinates))} is not valid")
                    return
                }
                parsedArray.append(currentPlace)
                return
            }
            guard let currentBuffer, currentBuffer != "" else { return }
            switch elementName {
            case "City":
                currentPlace?.city = currentBuffer.trimmingCharacters(in: .whitespaces)
            case "Address":
                currentPlace?.address = currentBuffer.trimmingCharacters(in: .whitespaces)
            case "Coordinates":
                let tmp = currentBuffer.components(separatedBy: ", ").map { Double($0) }
                guard tmp.count == 2, let tmp0 = tmp[0], let tmp1 = tmp[1] else {
                    fatalError("Wrong coordinate arguments")
                }
                currentPlace?.coordinates = (tmp0, tmp1)
            default:
                return
            }
        }
        
    }
    
    // MARK: - Stored values
    
    public let contents: [Place]
    public let cities: [City]
    
    // MARK: - Initializing
    
    public init() {
        guard let path = Bundle.main.path(forResource: "PlacesInfo", ofType: "xml") else {
            fatalError("Unable to find info file")
        }
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            print(error.localizedDescription)
            fatalError("Unable to get data by path: \(path)")
        }
        
        let xmlParser = XMLParser(data: data)
        let parser = Parser()
        xmlParser.delegate = parser
        xmlParser.parse()
        
        self.contents = parser.parsedArray
        
        var cities: [City] = []
        for el in self.contents {
            if let cityName = el.city, !cities.contains(where: { city in
                city.name == cityName
            }) {
                cities.append(City(name: cityName))
            }
        }
        self.cities = cities
    }

}
