Pod::Spec.new do |s|
  s.name                = "xgen"
  s.version             = "1.0.0"
  s.summary             = "xgen api framework"
  s.description         = "xgen api framework"
  s.homepage            = "https://github.com/CoCoPIE-Group/XGenOutputUsageDemo_iOS"
  s.author              = { "CoCoPIE-Group" => "" }
  s.platform            = :ios, "11.0"
  s.source              = {:path => '.'}
  s.requires_arc        = true
  s.vendored_frameworks = "xgen.framework"
  s.source_files        = 'xgen.framework/**/*.h'
  s.framework           = "Metal"
  s.libraries           = "z", "c++"
  s.xcconfig = {
       'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
       'CLANG_CXX_LIBRARY' => 'libc++'
  }
  
end


 
