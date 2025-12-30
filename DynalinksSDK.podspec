Pod::Spec.new do |s|
  s.name             = 'DynalinksSDK'
  s.version          = '1.0.1'
  s.summary          = 'Deferred deep linking SDK for iOS'

  s.description      = <<-DESC
    DynalinksSDK enables deferred deep linking for iOS apps, allowing attribution
    of app installs to specific marketing campaigns and deep link destinations.
    The SDK collects device fingerprints to match users who click links before
    installing your app, enabling seamless onboarding experiences.
  DESC

  s.homepage         = 'https://dynalinks.app'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dynalinks' => 'support@dynalinks.app' }
  s.source           = { :git => 'https://github.com/dynalinks/dynalinks-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '16.0'
  s.swift_version = '5.7'

  s.source_files = 'Sources/DynalinksSDK/**/*.swift'
  s.frameworks = 'Foundation', 'UIKit'
end
