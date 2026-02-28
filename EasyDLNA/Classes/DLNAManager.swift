
import Foundation

// MARK: - DLNAManager

public class DLNAManager: NSObject {
    public static let shared = DLNAManager()
    
    public weak var delegate: DLNADelegate?
    
    private let discovery = DLNADiscovery()
    private let control = DLNAControl()
    
    private var devices: [DLNADevice] = []
    
    public var currentDevice: DLNADevice? {
        get { control.currentDevice }
        set {
            control.currentDevice = newValue
            if let device = newValue {
                delegate?.dlnaDeviceConnected(device)
            }
        }
    }
    
    override init() {
        super.init()
        discovery.delegate = self
        control.delegate = self
    }
    
    public func startSearch() {
        devices.removeAll()
        delegate?.dlnaDevicesUpdated(devices)
        discovery.startSearch()
    }
    
    public func stopSearch() {
        discovery.stopSearch()
    }
    
    public func setAVTransportURI(url: String, title: String = "") {
        control.setAVTransportURI(url: url, title: title)
    }
    
    public func play() {
        control.play()
    }
    
    public func pause() {
        control.pause()
    }
    
    public func stop() {
        control.stop()
    }
    
    public func seek(to seconds: Int) {
        control.seek(to: seconds)
    }
    
    public func getPositionInfo() {
        control.getPositionInfo()
    }
    
    public func getTransportInfo() {
        control.getTransportInfo()
    }
}

extension DLNAManager: DLNADiscoveryDelegate {
    func discovery(_ discovery: DLNADiscovery, didFindDevice device: DLNADevice) {
        if !devices.contains(where: { $0.uuid == device.uuid }) {
            devices.append(device)
            delegate?.dlnaDevicesUpdated(devices)
        }
    }
}

extension DLNAManager: DLNAControlDelegate {
    func control(_ control: DLNAControl, didUpdateState isPlaying: Bool) {
        delegate?.dlnaStateUpdated(isPlaying: isPlaying)
    }
    
    func control(_ control: DLNAControl, didUpdatePosition current: TimeInterval, duration: TimeInterval) {
        delegate?.dlnaPositionUpdated(current: current, duration: duration)
    }
}
