source 'https://github.com/CocoaPods/Specs.git'
source 'https://bitbucket.org/tiagobras/tbpods'

use_frameworks!

def shared_pods
    pod 'Zip', '~> 1.0'
    pod 'SwiftyJSON', '~> 3.1.4'
    pod 'GRDB.swift', '~> 2.3.0'
    pod 'TBSwiftKit', '~> 0.0.11'
end

target 'ArkhamHorrorKit iOS' do
    platform :ios, '9.0'
    shared_pods
end

target 'ArkhamHorrorKit macOS' do
    platform :osx, ’10.10’
    shared_pods
end

target 'ArkhamHorrorKit iOSTests' do
    platform :ios, '9.0'
    shared_pods
end

target 'ArkhamHorrorKit macOSTests' do
    platform :osx, ’10.10’
    shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
