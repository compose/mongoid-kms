# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid/kms/version'

Gem::Specification.new do |spec|
  spec.name          = "mongoid-kms"
  spec.version       = Mongoid::Kms::VERSION
  spec.authors       = ["Chris Winslett"]
  spec.email         = ["chris@mongohq.com"]
  spec.summary       = %q{Easy plugin for Mongoid + AWS KMS for security}
  spec.description   = %q{Need to encrypt your datas?  Use AWS's KMS for data encryption.}
  spec.homepage      = "https://git.compose.io/compose/mongoid-kms"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid", "<5.0.0"
  spec.add_dependency "activesupport"
  spec.add_dependency "aws-sdk", "> 2.0.9.pre"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "byebug"
end
