#
# Be sure to run `pod lib lint DTConsole.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DTConsole'
  s.version          = '0.1.2'
  s.summary          = 'An on-device console for debugging purpose on iOS and tvOS'
  s.description      = 'An on-device console for debugging purpose on iOS and tvOS.'
  s.homepage         = 'https://github.com/eebean2/DTConsole'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Erik' => 'eebean2@me.com' }
  s.source           = { :git => 'https://github.com/eebean2/DTConsole.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'DTConsole/Classes/**/*'
  
  # s.resource_bundles = {
  #   'DTConsole' => ['DTConsole/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking', '~> 3.0'
  s.dependency 'Alamofire', '~> 4.0'
  s.dependency 'Auth0', '~> 1.0'
  s.dependency 'Lock', '~> 1.26'
end
