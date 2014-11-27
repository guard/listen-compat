# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'listen/compat/version'

Gem::Specification.new do |spec|
  spec.name          = 'listen-compat'
  spec.version       = Listen::Compat::VERSION
  spec.authors       = ['Cezary Baginski']
  spec.email         = ['cezary@chronomantic.net']
  spec.summary       = 'Simplified compatibility layer for Listen gem'
  spec.description   = 'For developers to have a minimal, guaranteed API for \
    using Listen'

  spec.homepage      = 'https://github.com/guard/listen-compat'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
