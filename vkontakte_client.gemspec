# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'vkontakte/version'

Gem::Specification.new do |gem|
  gem.authors       = ['Anton Maminov']
  gem.email         = ['anton.maminov@gmail.com']
  gem.description   = 'VKontakte API Client for Ruby'
  gem.summary       = 'Unofficial VKontakte API Client for Ruby'
  gem.homepage      = 'https://github.com/mamantoha/vkontakte_client'
  gem.licenses      = ['MIT']

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'vkontakte_client'
  gem.require_paths = ['lib']
  gem.version       = Vkontakte::VERSION
  gem.required_ruby_version = '>= 2.7.0'
  gem.add_runtime_dependency 'mechanize', '~> 2.8', '>= 2.8.0'
  gem.add_runtime_dependency 'socksify', '~> 1.7', '>= 1.7.0'
  gem.add_development_dependency 'pry', '~> 0.14', '>= 0.14.0'
  gem.add_development_dependency 'rubocop', '~> 1.18', '>= 1.18.0'
end
