//
//  PlacesInfoContainer.swift
//  Coffeeshop
//
//  Created by Vadim Popov on 08.02.2023.
//

import UIKit


class InfoContainer {
    
    // MARK: - One item
    
    public class Place: CustomStringConvertible {
        public var city: String?
        public var address: String?
        public var coordinates: (Double, Double)?
        
        public var description: String { "\(city ?? "nil"), \(address ?? "nil")" }
    
        public var isValid: Bool { city != nil && address != nil && coordinates != nil }
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
                guard let currentPlace, currentPlace.isValid else { return }
                parsedArray.append(currentPlace)
                return
            }
            guard let currentBuffer, currentBuffer != "" else { return }
            switch elementName {
            case "City":
                currentPlace?.city = currentBuffer
            case "Address":
                currentPlace?.address = currentBuffer
            case "Coordinates":
                let tmp = currentBuffer.components(separatedBy: ", ").map { Double($0) ?? -1.0 }
                if tmp.contains(0) {
                    fatalError("Wrong coordinate arguments")
                }
                currentPlace?.coordinates = (tmp[0], tmp[1])
            default:
                return
            }
        }
        
    }
    
    // MARK: - Stored values
    
    public let contents: [Place]
    
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
    }

}
