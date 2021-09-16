platform :ios, '12.4'
use_frameworks!

target 'BaseKeyboard' do
  pod 'Sentry', '=7.3.0'
  pod 'DivvunSpell', :http => "https://github.com/divvun/divvunspell-sdk-swift/releases/download/v1.0.0-beta.1/cargo-pod.tgz"
  pod 'UIDeviceComplete', :git => "https://github.com/bbqsrc/UIDeviceComplete"
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'RxSwift', '~> 5.1.1'
end

target 'HostingApp' do
  pod 'Sentry', '=7.3.0'
  pod 'UIDeviceComplete', :git => "https://github.com/bbqsrc/UIDeviceComplete"
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'PahkatClient', :http => "https://github.com/divvun/pahkat-client-sdk-swift/releases/download/v0.1.0/cargo-pod_ios.tgz"
end

target 'HostingAppTests' do
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'DivvunSpell', :http => "https://github.com/divvun/divvunspell-sdk-swift/releases/download/v1.0.0-beta.1/cargo-pod.tgz"
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
#      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = `uname -m`
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.4'
      config.build_settings['ARCHS'] = '$(ARCHS_STANDARD_64_BIT)'
      config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
    end
  end
end
