require 'bundler'
Bundler.require

require 'gem_polisher'
GemPolisher.new

desc "Run RSpec"
task :rspec do
  sh 'rspec --format=progress'
end
task test: [:rspec]

task default: [:test]
