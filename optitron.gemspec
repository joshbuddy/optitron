# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'optitron/version'

Gem::Specification.new do |s|
  s.name        = "optitron"
  s.version     = Optitron::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Joshua Hull']
  s.email       = ['joshbuddy@gmail.com']
  s.homepage    = "http://rubygems.org/gems/optitron"
  s.summary     = "Sensible options parsing"
  s.description = "Sensible options parsing"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "optitron"

  s.add_dependency "callsite", "~> 0.0.4"
  s.add_dependency "parameters_extra", "~> 0.2.0"
  s.add_development_dependency "bundler", "~> 1.0.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "phocus"

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
end