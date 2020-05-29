platform :ios, '12.4'
use_frameworks!

target 'BaseKeyboard' do
  pod 'Sentry', '=4.5.0'
  pod 'DivvunSpell', :git => "https://github.com/divvun/divvunspell-swift", :submodules => true
  pod 'UIDeviceComplete', :git => "https://github.com/bbqsrc/UIDeviceComplete"
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'RxSwift'
end

target 'HostingApp' do
  pod 'Sentry', '=4.5.0'
  pod 'UIDeviceComplete', :git => "https://github.com/bbqsrc/UIDeviceComplete"
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'PahkatClient', :git => "https://github.com/divvun/pahkat-client-sdk-swift/", :submodules => true
end

target 'HostingAppTests' do
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'DivvunSpell', :git => "https://github.com/divvun/divvunspell-swift", :submodules => true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
