
import Foundation
import CocoaAsyncSocket

protocol DLNADiscoveryDelegate: AnyObject {
    func discovery(_ discovery: DLNADiscovery, didFindDevice device: DLNADevice)
}

class DLNADiscovery: NSObject {
    weak var delegate: DLNADiscoveryDelegate?
    
    private var udpSocket: GCDAsyncUdpSocket?
    private var searchTimer: Timer?
    private var knownLocations: Set<String> = []
    
    override init() {
        super.init()
        setupSocket()
    }
    
    private func setupSocket() {
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }
    
    func startSearch() {
        knownLocations.removeAll()
        do {
            try udpSocket?.close()
            try udpSocket?.bind(toPort: 0)
            try udpSocket?.beginReceiving()
            
            sendMSearch()
            
            searchTimer?.invalidate()
            searchTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.sendMSearch()
            }
        } catch {
            print("DLNA: Socket error \(error)")
        }
    }
    
    func stopSearch() {
        searchTimer?.invalidate()
        searchTimer = nil
        udpSocket?.close()
    }
    
    private func sendMSearch() {
        let message = "M-SEARCH * HTTP/1.1\r\n" +
                      "HOST: 239.255.255.250:1900\r\n" +
                      "MAN: \"ssdp:discover\"\r\n" +
                      "MX: 3\r\n" +
                      "ST: urn:schemas-upnp-org:service:AVTransport:1\r\n" +
                      "\r\n"
        
        if let data = message.data(using: .utf8) {
            udpSocket?.send(data, toHost: "239.255.255.250", port: 1900, withTimeout: -1, tag: 0)
        }
    }
    
    private func handleSSDPResponse(_ data: Data) {
        guard let response = String(data: data, encoding: .utf8) else { return }
        let lines = response.components(separatedBy: "\r\n")
        guard let locationLine = lines.first(where: { $0.uppercased().hasPrefix("LOCATION:") }) else { return }
        let location = String(locationLine.dropFirst(9)).trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: location) else { return }
        
        if knownLocations.contains(location) { return }
        knownLocations.insert(location)
        
        fetchDeviceDescription(url: url, location: location)
    }
    
    private func fetchDeviceDescription(url: URL, location: String) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            let parser = DLNAXMLParser(data: data)
            if let info = parser.parse() {
                var controlURL = info.controlURL
                if !controlURL.hasPrefix("http") {
                    let baseURL = URL(string: "/", relativeTo: url)?.absoluteString ?? ""
                    if controlURL.hasPrefix("/") {
                        if let scheme = url.scheme, let host = url.host, let port = url.port {
                            controlURL = "\(scheme)://\(host):\(port)\(controlURL)"
                        } else {
                             controlURL = baseURL + String(controlURL.dropFirst())
                        }
                    } else {
                        controlURL = baseURL + controlURL
                    }
                }
                let device = DLNADevice(uuid: info.uuid, name: info.friendlyName, location: location, controlURL: controlURL)
                DispatchQueue.main.async {
                    self.delegate?.discovery(self, didFindDevice: device)
                }
            }
        }.resume()
    }
}

extension DLNADiscovery: GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        handleSSDPResponse(data)
    }
}