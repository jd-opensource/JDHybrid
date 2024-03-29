#
# Be sure to run `pod lib lint JDHybrid.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JDHybrid'
  s.version          = '1.0.4'
  s.summary          = 'A short description of JDHybrid.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/JDFED/JDHybrid.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JDHybrid' => 'jdapp-webview@jd.com' }
  s.source           = { :git => 'https://github.com/JDFED/JDHybrid.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'iOS/JDHybrid/JDHybrid.h'
  s.subspec 'JDBridge' do |a|
    a.source_files = 'iOS/JDHybrid/JDBridge/**/*.{h,m}'
    a.public_header_files = 'iOS/JDHybrid/JDBridge/Classes/JDBridgeBasePlugin.h',
                            'iOS/JDHybrid/JDBridge/Classes/JDBridgeManager.h',
                            'iOS/JDHybrid/JDBridge/JDBridge.h'
    a.frameworks = 'WebKit','UIKit','Foundation'
  end

  s.subspec 'JDCache' do |b|
    b.source_files = 'iOS/JDHybrid/JDCache/**/*.{h,m}'
    b.resource_bundles = {
      'JDCache' => ['iOS/JDHybrid/JDCache/Assets/*.js']
    }
    b.public_header_files = 'iOS/JDHybrid/JDCache/Classes/JDCache.h',
                            'iOS/JDHybrid/JDCache/Classes/JDCacheProtocol.h',
                            'iOS/JDHybrid/JDCache/Classes/Configure/JDCacheLoader.h',
                            'iOS/JDHybrid/JDCache/Classes/Configure/WKWebViewConfiguration+Loader.h',
                            'iOS/JDHybrid/JDCache/Classes/Preload/JDCachePreload.h',
                            'iOS/JDHybrid/JDCache/Classes/Utils/JDUtils.h',
                            'iOS/JDHybrid/JDCache/Classes/Utils/JDSafeDictionary.h',
                            'iOS/JDHybrid/JDCache/Classes/Utils/JDSafeArray.h',
    b.frameworks = 'WebKit','UIKit','Foundation'
    b.dependency 'JDHybrid/JDBridge'
  end
  
  s.subspec 'JDWebView' do |c|
    c.source_files = 'iOS/JDHybrid/JDWebView/**/*.{h,m}'
    c.public_header_files = 'iOS/JDHybrid/JDWebView/Classes/JDWebViewContainer.h',
                            'iOS/JDHybrid/JDWebView/JDWebView.h'
    c.frameworks = 'WebKit','UIKit','Foundation'
    c.dependency 'JDHybrid/JDBridge'
  end

end
