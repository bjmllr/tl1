# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tl1/version'

Gem::Specification.new do |spec|
  spec.name          = 'tl1'
  spec.version       = Tl1::VERSION
  spec.authors       = ['Ben Miller']
  spec.email         = ['bmiller@rackspace.com']

  spec.summary       = 'Define, send, and receive TL1 messages'
  spec.homepage      = 'https://github.com/bjmllr/tl1'
  spec.license       = 'GPL-3.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
