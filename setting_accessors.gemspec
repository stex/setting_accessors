# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'setting_accessors/version'

Gem::Specification.new do |spec|
  spec.name          = 'setting_accessors'
  spec.version       = SettingAccessors::VERSION
  spec.authors       = ["Stefan Exner"]
  spec.email         = ["stex@sterex.de"]
  spec.summary       = %q{Attributes without database changes. The future? (JK)}
  spec.description   = %q{Longer description.}
  spec.homepage      = 'https://www.github.com/stex/setting_accessors'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'shoulda'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'factory_girl'

  spec.add_dependency 'rails', '~> 4'
end
