
Pod::Spec.new do |s|
  s.name         = "ArkhamHorrorKit"
  s.version      = "0.0.3"
  s.summary      = "Arhkahm Horror SDK"
  s.description  = <<-DESC
  A module with Arkham Horror LCG cards database and related helper classes.
  DESC

  s.homepage     = "https://tiagobras@bitbucket.org/tiagobras/arkhamhorrorkit.git"
  s.license      = "MIT"
  s.author             = { "Tiago Bras" => "tiagodsbras@gmail.com" }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source       = { :git => "https://tiagobras@bitbucket.org/tiagobras/arkhamhorrorkit.git", :tag => s.version.to_s }
  s.source_files  = "ArkhamHorrorKit/*.h", "ArkhamHorrorKit/Database", "ArkhamHorrorKit/Card Models"
  s.pod_target_xcconfig = {
    "SWIFT_VERSION" => "4.0",
    "APPLICATION_EXTENSION_API_ONLY" => "YES"
  }

end
