lib = File.expand_path('lib', __dir__)2
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cmdb/version'

Gem::Specification.new do |spec|
  spec.name          = 'cmdb'
  spec.version       = CMDB::VERSION
  spec.authors       = ['RightScale']
  spec.email         = ['rubygems@rightscale.com']

  spec.summary       = 'Command-line tool for configuration manegement databases'
  spec.description   = 'Reads CMDB variables from files, Consul, and elsewhere.'
  spec.homepage      = 'https://github.com/rightscale/cmdb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('~> 2.0')

  spec.add_dependency 'diplomat', '>= 2.6.4'
  spec.add_dependency 'listen', '~> 3.0'
  spec.add_dependency 'trollop', '~> 2.0'

  spec.add_development_dependency 'bundler', '~> 1.10'
end
