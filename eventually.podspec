Pod::Spec.new do |spec|
  spec.name         = 'eventually'
  spec.version      = '0.0.1'
  spec.license      =  { :type => 'BSD' }
  spec.homepage     = 'https://github.com/mproberts/eventually'
  spec.authors      = { 'Mike Roberts' => 'mike@kik.com' }
  spec.summary      = 'Lightweight, scoped eventing framework for Objective-c (and other languages)'
  spec.platform     = :ios
  spec.source       = { :git => 'https://github.com/mproberts/eventually.git', :tag => '0.0.1' }
  spec.source_files = 'src/**/*.{h,m,mm,cpp}'
  spec.public_header_files = 'eventually/{Eventually}.h'
  spec.requires_arc = true
  spec.library = 'c++'
  spec.xcconfig = {
       'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
       'CLANG_CXX_LIBRARY' => 'libc++'
  }

  spec.ios.deployment_target = '6.0'
end
