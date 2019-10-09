platform :ios, '9.0'
use_frameworks!

target 'BaseKeyboard' do
  pod 'Sentry'
  pod 'libdivvunspell', :git => "https://github.com/bbqsrc/divvunspell-swift", :submodules => true
end

target 'HostingApp' do
  pod 'Sentry'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
