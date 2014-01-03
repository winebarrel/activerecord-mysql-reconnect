# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord/mysql/reconnect/version'

Gem::Specification.new do |spec|
  spec.name          = "activerecord-mysql-reconnect"
  spec.version       = Activerecord::Mysql::Reconnect::VERSION
  spec.authors       = ["Genki Sugawara"]
  spec.email         = ["sugawara@cookpad.com"]
  spec.description   = %q{It is the library to reconnect automatically when ActiveRecord is disconnected from MySQL.}
  spec.summary       = spec.description
  spec.homepage      = "https://bitbucket.org/winebarrel/activerecord-mysql-reconnect"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 3.2.14"
  spec.add_dependency "retryable", "~> 1.3.3"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
