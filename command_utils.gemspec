Gem::Specification.new do |s|
  s.name        = 'command_utils'
  s.version     = '0.2.0'
  s.summary     = "Simple Gem to assist running external commands an processing its outputs."
  s.description = "This Gem will help you call external commands, process its stdout and stderr, to your own fit, and at the end, validate its return code."
  s.authors     = ["Fabio Pugliese Ornellas"]
  s.email       = 'fabio.ornellas@gmail.com'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'guard-rspec', '~> 4.5'
  s.add_development_dependency 'guard-rdoc', '~> 1.0', '>= 1.0.3'
  s.files       = Dir.glob('lib/**/*.rb')
  s.homepage    = 'https://github.com/fornellas/command_utils'
  s.license     = 'GPL'
end
