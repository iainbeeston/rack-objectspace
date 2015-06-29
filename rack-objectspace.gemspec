# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/objectspace/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-objectspace"
  spec.version       = Rack::Objectspace::VERSION
  spec.authors       = ["Iain Beeston"]
  spec.email         = ["iain.beeston@gmail.com"]

  spec.summary       = %q{Saves objectspace to a key-value store after every request}
  spec.homepage      = "http://github.com/iainbeeston/rack-objectspace"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec|tmp)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.1'

  spec.add_dependency "rack"
  spec.add_dependency "yajl-ruby"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "moneta", "~> 0.8"
end
