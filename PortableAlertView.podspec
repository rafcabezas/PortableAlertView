Pod::Spec.new do |s|
  s.name         = "PortableAlertView"
  s.version      = "0.0.1"
  s.summary      = "Cocoa/Cocoa Touch Block-based alert view system for iOS/Mac"
  s.description  = <<-DESC
                   Cocoa/Cocoa Touch Block-based alert view system for iOS/Mac

                   * Shared header file between platforms
                   * Simply use the appropriate module for your platform in your
                   * xcode target.
                   * Block based
                   DESC
  s.homepage     = "https://github.com/rafcabezas/PortableAlertView"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Raf" => "raf@remoterlabs.com" }
  s.social_media_url = "http://twitter.com/rafcabezas"
  s.platform     = :ios, '6.0'
  s.osx.deployment_target = '10.7'
  s.source       = { :git => "https://github.com/rafcabezas/PortableAlertView.git", :tag => "0.0.1" }
  s.source_files = "*.{m,h}"
  s.ios.exclude_files = "*_{Mac,Win32}.m"
  s.osx.exclude_files = "*_{iOS,Win32}.m"
  s.requires_arc = true
end
