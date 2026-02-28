
import Foundation

class DLNAXMLParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    
    var friendlyName: String = ""
    var uuid: String = ""
    var controlURL: String = ""
    
    private var currentElement = ""
    private var foundAVTransport = false
    private var tempFriendlyName = ""
    private var tempUUID = ""
    private var tempControlURL = ""
    
    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        self.parser.delegate = self
    }
    
    func parse() -> (friendlyName: String, uuid: String, controlURL: String)? {
        if parser.parse() && !controlURL.isEmpty {
            return (friendlyName, uuid, controlURL)
        }
        return nil
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return }
        
        if currentElement == "friendlyName" && friendlyName.isEmpty {
            tempFriendlyName += value
        } else if currentElement == "UDN" && uuid.isEmpty {
            tempUUID += value
        } else if currentElement == "serviceType" {
            if value.contains("AVTransport:1") {
                foundAVTransport = true
            }
        } else if currentElement == "controlURL" && foundAVTransport {
            tempControlURL += value
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "friendlyName" && friendlyName.isEmpty {
            friendlyName = tempFriendlyName
            tempFriendlyName = ""
        } else if elementName == "UDN" && uuid.isEmpty {
            uuid = tempUUID.replacingOccurrences(of: "uuid:", with: "")
            tempUUID = ""
        } else if elementName == "service" {
            if foundAVTransport && !tempControlURL.isEmpty {
                controlURL = tempControlURL
            }
            foundAVTransport = false
            tempControlURL = ""
        }
    }
}