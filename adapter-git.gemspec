# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adapter/git/version"

Gem::Specification.new do |s|
  s.name        = "adapter-git"
  s.version     = Adapter::Git::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = ""
  s.summary     = %q{Adapter for git}
  s.description = %q{Adapter for git}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'adapter', '~> 0.5.1'
  s.add_dependency 'grit', '~> 2.0'
  s.add_development_dependency 'rspec', '~> 2.0'
  s.add_development_dependency 'rake'
end
