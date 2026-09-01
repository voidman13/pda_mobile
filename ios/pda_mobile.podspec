Pod::Spec.new do |s|
  s.name             = 'pda_mobile'
  s.version          = '1.0.0'
  s.summary          = 'Flutter bridge for the BLD N60 barcode scanner.'
  s.description      = <<-DESC
Flutter bridge for the BLD N60 barcode scanner. The iOS implementation keeps
the shared example and keyboard APIs available while reporting that the
Android-specific BLD scanner hardware is unavailable.
                       DESC
  s.homepage         = 'https://example.com/pda_mobile'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'pda_mobile' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
