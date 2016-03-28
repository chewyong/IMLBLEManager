#
# Be sure to run `pod lib lint IMLBLEManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "IMLBLEManager"
  s.version          = "0.0.1"
  s.summary          = "BLE Manager."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = "Used to scan the BEL Periphearl, connect the BEL Periphearl to send a message to the BEL Periphearl "

  s.homepage         = "https://github.com/chewyong/IMLBLEManager"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "chewyong" => "603487153@qq.com" }
  s.source           = { :git => "https://github.com/chewyong/IMLBLEManager.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'IMLBLEManager' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreBluetooth'
  # s.dependency 'AFNetworking', '~> 2.3'
end
