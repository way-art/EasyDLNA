
import Foundation

public struct DLNADevice: Equatable {
    public let uuid: String
    public var name: String
    public let location: String
    public var controlURL: String?
}

public protocol DLNADelegate: AnyObject {
    func dlnaDevicesUpdated(_ devices: [DLNADevice])
    func dlnaDeviceConnected(_ device: DLNADevice)
    func dlnaStateUpdated(isPlaying: Bool)
    func dlnaPositionUpdated(current: TimeInterval, duration: TimeInterval)
}