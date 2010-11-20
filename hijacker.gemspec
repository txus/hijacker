# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hijacker/version"

Gem::Specification.new do |s|
  s.name        = "hijacker"
  s.version     = Hijacker::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Josep M. Bach"]
  s.email       = ["josep.m.bach@gmail.com"]
  s.homepage    = "http://github.com/txus/hijacker"
  s.summary     = %q{Spy on your ruby objects and send their activity to a hijacker server anywhere through DRb}
  s.description = %q{Spy on your ruby objects and send their activity to a hijacker server anywhere through DRb}

  s.rubyforge_project = "hijacker"

  s.add_runtime_dependency 'trollop'
  s.default_executable = "hijacker"

  s.add_development_dependency 'bundler', '~> 1.0.7'
  s.add_development_dependency 'rspec',   '~> 2.1.0'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency "simplecov"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
