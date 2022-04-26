Pod::Spec.new do |spec|
  spec.name         = "Armin"
  spec.version      = "1.0.10"
  spec.summary      = "Armin is a http/https request service."
  spec.homepage     = "https://github.com/CavanSu/Armin"
  spec.license      = "MIT"
  spec.author             = { "CavanSu" => "403029552@qq.com" }
  spec.ios.deployment_target = "10.0"
  spec.osx.deployment_target = "10.10"
  spec.source       = { :git => "https://github.com/CavanSu/Armin.git", :tag => "#{spec.version}" }

  spec.source_files  = "sources/**/*.{h,m,swift}"
  spec.module_name   = 'Armin'
  spec.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4']
  spec.xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'DEFINES_MODULE' => 'YES' }
  spec.pod_target_xcconfig = { 'VALID_ARCHS' => 'arm64 armv7 x86_64' }
  spec.user_target_xcconfig = { 'VALID_ARCHS' => 'arm64 armv7 x86_64' }
end
