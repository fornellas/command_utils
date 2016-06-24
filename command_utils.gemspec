require_relative 'lib/command_utils/version'

Gem::Specification.new do |s|
  s.name        = 'command_utils'
  s.version     = CommandUtils::VERSION
  s.summary     = "Simple Gem to assist running external commands an processing its outputs."
  s.description = "This Gem will help you call external commands, process its stdout and stderr, to your own fit, and at the end, validate its return code."
  s.authors     = ["Fabio Pugliese Ornellas"]
  s.email       = 'fabio.ornellas@gmail.com'
  s.required_ruby_version = '~> 2.1'
  s.add_development_dependency 'gem_polisher', '~>0.4', '>=0.4.12'
  s.add_development_dependency 'rspec', '~>3.3'
  s.add_development_dependency 'simplecov', '~>0.10'
  s.add_development_dependency 'coderay', '~>1.1', '>=1.1.1'
  s.add_development_dependency 'rake', '~>10.4', '>= 10.4.2'
  s.files       = Dir.glob('lib/**/*.rb')
  s.homepage    = 'https://github.com/fornellas/command_utils'
  s.license     = 'GPL'
end
