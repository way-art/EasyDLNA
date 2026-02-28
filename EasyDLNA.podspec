#
# Be sure to run `pod lib lint EasyDLNA.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EasyDLNA'
  s.version          = '1.0.0'
  s.summary          = 'EasyDLNA is a lightweight DLNA casting tool written in Swift'

  s.description      = <<-DESC
EasyDLNA is a lightweight DLNA casting tool written in Swift. It encapsulates the SSDP discovery protocol and SOAP control protocol, providing a simple and easy-to-use API for iOS developers to implement screen casting functionalities (Play, Pause, Seek, Volume Control, etc.) on Smart TVs or TV Boxes.
                       DESC

  s.homepage         = 'https://github.com/way-art/EasyDLNA'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'way-art' => 'https://github.com/way-art' }
  s.source           = { :git => 'https://github.com/way-art/EasyDLNA.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.source_files = 'EasyDLNA/Classes/**/*'
  s.dependency 'CocoaAsyncSocket'
end
