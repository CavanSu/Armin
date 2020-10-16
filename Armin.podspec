#
#  Be sure to run `pod spec lint Armin.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "Armin"
  spec.version      = "1.0.0"
  spec.summary      = "Armin is a http/https request service."
  spec.homepage     = "https://github.com/CavanSu/Armin"
  spec.license      = "MIT"
  spec.author             = { "CavanSu" => "403029552@qq.com" }
  spec.ios.deployment_target = "9.0"
  spec.osx.deployment_target = "10.10"
  spec.source       = { :git => "https://github.com/CavanSu/Armin.git", :tag => "#{spec.version}" }

  spec.source_files  = "sources/*.{h,m,swift}"
  spec.dependency "Alamofire", "~> 4.7.3"
  spec.module_name   = 'Armin'
  spec.swift_version = '4.0'
  
end
