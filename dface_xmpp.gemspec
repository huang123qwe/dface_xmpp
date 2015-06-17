# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dface_xmpp/version'

Gem::Specification.new do |spec|
  spec.name          = "dface_xmpp"
  spec.version       = DfaceXmpp::VERSION
  spec.authors       = ["pulsen"]
  spec.email         = ["hunag123qwe@126.com"]
  spec.summary       = %q{脸脸xmpp发送}
  spec.description   = %q{脸脸xmpp发送}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
