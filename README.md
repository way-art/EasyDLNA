# EasyDLNA

[中文说明](#中文说明) | [English](#english)

---

## <a id="english">English</a>

**EasyDLNA** is a lightweight DLNA casting tool written in Swift. It encapsulates the SSDP discovery protocol and SOAP control protocol, providing a simple and easy-to-use API for iOS developers to implement screen casting functionalities (Play, Pause, Seek, Volume Control, etc.) on Smart TVs or TV Boxes.

### 1. iOS DLNA Principles & Permissions

#### Principles
DLNA (Digital Living Network Alliance) on iOS typically relies on the UPnP (Universal Plug and Play) architecture:
*   **Discovery (SSDP)**: Uses UDP Multicast (Address: `239.255.255.250`, Port: `1900`) to discover devices on the same local network.
*   **Control (SOAP)**: Uses TCP/HTTP to send XML commands (SOAP) to the device's control URL to manage playback (AVTransport service).

#### System Permissions & Requirements
To ensure EasyDLNA works correctly on iOS devices, you must handle the following permissions:

1.  **Local Network Privacy (iOS 14+)**:
    *   Apple introduced strict local network privacy controls in iOS 14.
    *   You must add the `NSLocalNetworkUsageDescription` key to your `Info.plist` file explaining why your app needs access to the local network (e.g., "Used to discover and connect to TV devices").
    
2.  **Multicast Networking Entitlement**:
    *   Since SSDP relies on UDP Multicast, and iOS restricts arbitrary multicast traffic, you may need the **Multicast Networking Entitlement** (`com.apple.developer.networking.multicast`) for stable discovery.
    *   **How to apply**: You must apply for this entitlement through the Apple Developer portal. Once granted, enable it in your App ID and Xcode capabilities.

### 2. Architecture & Requirements

#### Architecture
The tool follows a layered architecture to separate concerns:

*   **DLNAManager (Facade)**: The main entry point. It manages the singleton instance, coordinates discovery and control modules, and exposes a unified API to the UI layer.
*   **DLNADiscovery**: Responsible for sending SSDP M-SEARCH packets via UDP and parsing response packets to find available devices (`DLNADevice`).
*   **DLNAControl**: Handles the connection to a specific device and sends SOAP actions (Play, Pause, SetURI) via HTTP.
*   **DLNAXMLParser**: Parses the XML responses from DLNA devices to extract information like friendly names, UUIDs, and transport states.
*   **DLNAModels**: Defines data structures like `DLNADevice`.

#### System Requirements
*   **iOS**: 12.0+ (Recommended)
*   **Swift**: 5.0+

### 3. Usage

#### Initialization
Set the delegate to receive callbacks.

```swift
import EasyDLNA

class ViewController: UIViewController, DLNADelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DLNAManager.shared.delegate = self
    }
    
    // MARK: - DLNADelegate
    func dlnaDevicesUpdated(_ devices: [DLNADevice]) {
        print("Found devices: \(devices.count)")
    }
    
    func dlnaDeviceConnected(_ device: DLNADevice) {
        print("Connected to: \(device.name)")
    }
    
    func dlnaStateUpdated(isPlaying: Bool) {
        print("Is Playing: \(isPlaying)")
    }
    
    func dlnaPositionUpdated(current: TimeInterval, duration: TimeInterval) {
        print("Progress: \(current) / \(duration)")
    }
}
```

#### Discovery
Start searching for devices.

```swift
DLNAManager.shared.startSearch()
// To stop searching:
// DLNAManager.shared.stopSearch()
```

#### Connect & Play
Once a device is selected from the list, connect to it and cast media.

```swift
func didSelect(device: DLNADevice) {
    // 1. Set the current device
    DLNAManager.shared.currentDevice = device
    
    // 2. Cast a video URL
    let videoURL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    DLNAManager.shared.setAVTransportURI(url: videoURL, title: "Big Buck Bunny")
    
    // 3. Start playback
    DLNAManager.shared.play()
}
```

#### Playback Control

```swift
DLNAManager.shared.pause()
DLNAManager.shared.play()
DLNAManager.shared.stop()
DLNAManager.shared.seek(to: 60) // Seek to 60 seconds
```

---

## <a id="中文说明">中文说明</a>

**EasyDLNA** 是一个使用 Swift 编写的轻量级 DLNA 投屏工具。它封装了底层 SSDP 发现协议和 SOAP 控制协议，为 iOS 开发者提供了一套简单易用的 API，用于实现向智能电视或电视盒子投送视频、控制播放（播放、暂停、进度跳转等）的功能。

### 1. iOS DLNA 原理与权限要求

#### 原理简介
iOS 上的 DLNA 功能通常基于 UPnP（通用即插即用）架构实现：
*   **设备发现 (SSDP)**：通过 UDP 组播（地址：`239.255.255.250`，端口：`1900`）向局域网发送搜索请求，并监听设备响应。
*   **设备控制 (SOAP)**：获取设备信息后，通过 TCP/HTTP 协议向设备的控制 URL 发送 XML 格式的指令（SOAP），主要操作 AVTransport 服务。

#### 系统权限与证书申请
为了在 iOS 设备上正常使用投屏功能，需要处理以下权限：

1.  **本地网络权限 (Local Network Privacy - iOS 14+)**：
    *   iOS 14 及以上系统引入了本地网络隐私权限。
    *   必须在 `Info.plist` 中添加 `NSLocalNetworkUsageDescription` 键，并填写描述（例如：“App 需要访问本地网络以发现并连接电视设备”）。
    
2.  **组播网络权限 (Multicast Networking Entitlement)**：
    *   由于 SSDP 依赖 UDP 组播，而苹果对组播流量有严格限制，为了保证设备发现的稳定性，通常需要申请 **Multicast Networking Entitlement** (`com.apple.developer.networking.multicast`)。
    *   **申请方式**：需通过 Apple Developer 网站 向苹果提交申请。审核通过后，在 App ID 和 Xcode 的 Signing & Capabilities 中开启该权限。

### 2. 架构分层与系统支持

#### 架构说明
本工具采用分层架构设计，职责清晰：

*   **DLNAManager (Facade 门面)**：核心管理类，单例模式。负责协调发现和控制模块，对外提供统一的 API 接口。
*   **DLNADiscovery**：负责底层的 UDP 组播搜索，发送 M-SEARCH 报文并解析回包，生成 `DLNADevice` 对象。
*   **DLNAControl**：负责与特定设备建立连接，封装 SOAP 协议并通过 HTTP 发送播放、暂停、设置链接等指令。
*   **DLNAXMLParser**：负责解析 DLNA 设备返回的 XML 数据，提取设备名称、UUID、控制地址等信息。
*   **DLNAModels**：定义数据模型，如 `DLNADevice`。

#### 支持系统
*   **iOS**: 12.0+ (推荐)
*   **Swift**: 5.0+

### 3. API 用法

#### 初始化
设置代理以接收设备列表更新和状态回调。

```swift
import EasyDLNA

class ViewController: UIViewController, DLNADelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DLNAManager.shared.delegate = self
    }
    
    // MARK: - DLNADelegate
    func dlnaDevicesUpdated(_ devices: [DLNADevice]) {
        print("发现设备数: \(devices.count)")
    }
    
    func dlnaDeviceConnected(_ device: DLNADevice) {
        print("已连接设备: \(device.name)")
    }
    
    func dlnaStateUpdated(isPlaying: Bool) {
        print("播放状态: \(isPlaying ? "播放中" : "暂停")")
    }
    
    func dlnaPositionUpdated(current: TimeInterval, duration: TimeInterval) {
        print("进度: \(current) / \(duration)")
    }
}
```

#### 搜索设备
开始搜索局域网内的 DLNA 设备。

```swift
DLNAManager.shared.startSearch()
// 停止搜索:
// DLNAManager.shared.stopSearch()
```

#### 连接与投屏
从列表中选择一个设备，建立连接并推送视频地址。

```swift
func didSelect(device: DLNADevice) {
    // 1. 设置当前操作的设备
    DLNAManager.shared.currentDevice = device
    
    // 2. 设置投屏地址 (视频 URL)
    let videoURL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    DLNAManager.shared.setAVTransportURI(url: videoURL, title: "测试视频")
    
    // 3. 开始播放
    DLNAManager.shared.play()
}
```

#### 播放控制

```swift
DLNAManager.shared.pause()        // 暂停
DLNAManager.shared.play()         // 播放
DLNAManager.shared.stop()         // 停止
DLNAManager.shared.seek(to: 60)   // 跳转到第 60 秒
```