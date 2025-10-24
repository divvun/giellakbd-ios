platform :ios, '13.0'
use_frameworks!

target 'BaseKeyboard' do
  pod 'Sentry', '8.53.1'
  pod 'DivvunSpell', :http => "https://github.com/divvun/divvunspell-sdk-swift/releases/download/v1.0.0-beta.5/cargo-pod.tgz"
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.15.3'
  pod 'RxSwift', '~> 5.1.1'
  pod 'DeviceKit', '~> 5.7'
end

target 'HostingApp' do
  pod 'Sentry', '8.53.1'
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.15.3'
  pod 'PahkatClient', :http => "https://github.com/divvun/pahkat-client-sdk-swift/releases/download/v0.2.3/cargo-pod.tgz"
end

target 'HostingAppTests' do
  pod 'SQLite.swift', '~> 0.15.3'
  pod 'DivvunSpell', :http => "https://github.com/divvun/divvunspell-sdk-swift/releases/download/v1.0.0-beta.5/cargo-pod.tgz"
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
#      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = `uname -m`
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ARCHS'] = '$(ARCHS_STANDARD_64_BIT)'
      config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
    end
  end
end
