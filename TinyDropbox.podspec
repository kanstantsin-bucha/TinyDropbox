#
# Be sure to run `pod lib lint TinyDropbox.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TinyDropbox'
  s.version          = '1.0.1'
  s.summary          = 'Easy to use dropbox sync for swift coders [wrapper on TBDropboxKit]'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
    Easy to use dropbox sync for swift coders [wrapper on TBDropboxKit] Could list files, upload, download and
    watching server changes
                       DESC

  s.homepage         = 'https://github.com/truebucha/TinyDropbox'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'truebucha' => 'truebucha@gmail.com' }
  s.source           = { :git => 'https://github.com/truebucha/TinyDropbox.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/truebucha'

  s.ios.deployment_target = '9.0'

  s.source_files = 'TinyDropbox/Classes/**/*.{swift}'


  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'Foundation'
  s.dependency 'TBDropboxKit', '~> 1.1'
  s.dependency 'BuchaSwift', '~> 1.0'
end
