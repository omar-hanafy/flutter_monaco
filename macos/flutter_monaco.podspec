#
# Podspec for the flutter_monaco macOS native plugin.
# Run `pod lib lint flutter_monaco.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_monaco'
  s.version          = '4.0.0'
  s.summary          = 'Native macOS focus integration for flutter_monaco.'
  s.description      = <<-DESC
Performs the NSWindow first-responder handoff between the Flutter view and the
WKWebView hosting the Monaco editor. The Dart side of flutter_monaco talks to
this plugin over the flutter_monaco/native_focus method channel.
                       DESC
  s.homepage         = 'https://github.com/omar-hanafy/flutter_monaco'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Omar Hanafy' => 'https://github.com/omar-hanafy' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_monaco/Sources/flutter_monaco/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.frameworks       = 'WebKit'

  s.platform = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
