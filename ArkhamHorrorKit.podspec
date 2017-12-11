
Pod::Spec.new do |s|
  s.name         = "ArkhamHorrorKit"
  s.version      = "0.0.37"
  s.summary      = "Arhkahm Horror SDK"
  s.description  = <<-DESC
  A module with Arkham Horror LCG cards database and related helper classes.
  DESC

  s.homepage     = "https://tiagobras@bitbucket.org/tiagobras/arkhamhorrorkit.git"
  s.license      = "MIT"
  s.author             = { "Tiago Bras" => "tiagodsbras@gmail.com" }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.source       = { :git => "https://tiagobras@bitbucket.org/tiagobras/arkhamhorrorkit.git", :tag => s.version.to_s }
  s.source_files  = "ArkhamHorrorKit/*.h", "ArkhamHorrorKit/*.swift", "ArkhamHorrorKit/**/*.swift"

  s.resources = "ArkhamHorrorKit/Resources/*.{xcassets,json,sql}"
  s.dependency 'SwiftyJSON', '~> 3.1.4'
  s.dependency 'GRDB.swift', '~> 2.3.0'
  s.dependency 'TBSwiftKit', '~> 0.0.20'
end
