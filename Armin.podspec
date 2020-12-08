Pod::Spec.new do |spec|
  spec.name         = "Armin"
  spec.version      = "1.0.4"
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
