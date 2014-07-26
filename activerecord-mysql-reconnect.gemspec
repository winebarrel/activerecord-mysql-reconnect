# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord/mysql/reconnect/version'

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-mysql-reconnect'
  spec.version       = Activerecord::Mysql::Reconnect::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@cookpad.com']
  spec.description   = %q{It is the library to reconnect automatically when ActiveRecord is disconnected from MySQL.}
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/winebarrel/activerecord-mysql-reconnect'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # '~> 3.2.19' or '~> 4.0.8' or '~> 4.1.4'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'mysql2'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'rspec-instafail'
end
