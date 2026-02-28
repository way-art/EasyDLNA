
import Foundation

protocol DLNAControlDelegate: AnyObject {
    func control(_ control: DLNAControl, didUpdateState isPlaying: Bool)
    func control(_ control: DLNAControl, didUpdatePosition current: TimeInterval, duration: TimeInterval)
}

class DLNAControl {
    weak var delegate: DLNAControlDelegate?
    var currentDevice: DLNADevice?
    
    func setAVTransportURI(url: String, title: String = "") {
        guard let controlURL = currentDevice?.controlURL else { return }
        let metaData = """
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">
        <item id="0" parentID="-1" restricted="0">
        <dc:title>\(title)</dc:title>
        <upnp:class>object.item.videoItem</upnp:class>
        <res protocolInfo="http-get:*:*:*">\(url)</res>
        </item>
        </DIDL-Lite>
        """
        let escapedMeta = metaData.xmlEscaped
        let body = """
        <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        <CurrentURI>\(url.xmlEscaped)</CurrentURI>
        <CurrentURIMetaData>\(escapedMeta)</CurrentURIMetaData>
        </u:SetAVTransportURI>
        """
        sendAction("SetAVTransportURI", body: body, to: controlURL) { [weak self] success, _ in
            if success { self?.play() }
        }
    }
    
    func play() {
        guard let controlURL = currentDevice?.controlURL else { return }
        let body = """
        <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        <Speed>1</Speed>
        </u:Play>
        """
        sendAction("Play", body: body, to: controlURL) { [weak self] success, _ in
            if success {
                guard let self = self else { return }
                DispatchQueue.main.async { self.delegate?.control(self, didUpdateState: true) }
            }
        }
    }
    
    func pause() {
        guard let controlURL = currentDevice?.controlURL else { return }
        let body = """
        <u:Pause xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        </u:Pause>
        """
        sendAction("Pause", body: body, to: controlURL) { [weak self] success, _ in
            if success {
                guard let self = self else { return }
                DispatchQueue.main.async { self.delegate?.control(self, didUpdateState: false) }
            }
        }
    }
    
    func stop() {
        guard let controlURL = currentDevice?.controlURL else { return }
        let body = """
        <u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        </u:Stop>
        """
        sendAction("Stop", body: body, to: controlURL) { [weak self] success, _ in
            if success {
                guard let self = self else { return }
                DispatchQueue.main.async { self.delegate?.control(self, didUpdateState: false) }
            }
        }
    }
    
    func seek(to seconds: Int) {
        guard let controlURL = currentDevice?.controlURL else { return }
        let timeStr = formatTime(TimeInterval(seconds))
        let body = """
        <u:Seek xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        <Unit>REL_TIME</Unit>
        <Target>\(timeStr)</Target>
        </u:Seek>
        """
        sendAction("Seek", body: body, to: controlURL, completion: nil)
    }
    
    func getPositionInfo() {
        guard let controlURL = currentDevice?.controlURL else { return }
        let body = """
        <u:GetPositionInfo xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        </u:GetPositionInfo>
        """
        sendAction("GetPositionInfo", body: body, to: controlURL) { [weak self] success, responseXML in
            guard let self = self, success, let xml = responseXML else { return }
            let relTimeStr = self.extractValue(from: xml, tag: "RelTime")
            let durationStr = self.extractValue(from: xml, tag: "TrackDuration")
            let current = self.parseTime(relTimeStr)
            let duration = self.parseTime(durationStr)
            DispatchQueue.main.async {
                self.delegate?.control(self, didUpdatePosition: current, duration: duration)
            }
        }
    }
    
    func getTransportInfo() {
        guard let controlURL = currentDevice?.controlURL else { return }
        let body = """
        <u:GetTransportInfo xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
        <InstanceID>0</InstanceID>
        </u:GetTransportInfo>
        """
        sendAction("GetTransportInfo", body: body, to: controlURL) { [weak self] success, responseXML in
            guard let self = self, success, let xml = responseXML else { return }
            let state = self.extractValue(from: xml, tag: "CurrentTransportState")
            let isPlaying = (state == "PLAYING" || state == "TRANSITIONING")
            DispatchQueue.main.async {
                self.delegate?.control(self, didUpdateState: isPlaying)
            }
        }
    }
    
    private func sendAction(_ action: String, body: String, to urlStr: String, completion: ((Bool, String?) -> Void)?) {
        guard let url = URL(string: urlStr) else { completion?(false, nil); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.addValue("\"urn:schemas-upnp-org:service:AVTransport:1#\(action)\"", forHTTPHeaderField: "SOAPAction")
        let envelope = """
        <?xml version="1.0" encoding="utf-8"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>\(body)</s:Body>
        </s:Envelope>
        """
        request.httpBody = envelope.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion?(false, nil); return }
            guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else { completion?(false, nil); return }
            let respString = data != nil ? String(data: data!, encoding: .utf8) : nil
            completion?(true, respString)
        }.resume()
    }
    
    private func extractValue(from xml: String, tag: String) -> String {
        guard let startRange = xml.range(of: "<\(tag)>"),
              let endRange = xml.range(of: "</\(tag)>") else { return "" }
        return String(xml[startRange.upperBound..<endRange.lowerBound])
    }
    
    private func parseTime(_ timeStr: String) -> TimeInterval {
        let parts = timeStr.components(separatedBy: ":")
        guard parts.count == 3 else { return 0 }
        return (Double(parts[0]) ?? 0) * 3600 + (Double(parts[1]) ?? 0) * 60 + (Double(parts[2]) ?? 0)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}