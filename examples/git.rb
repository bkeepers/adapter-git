require 'rubygems'
require 'pathname'

$:.unshift File.expand_path('../../lib', __FILE__)

require 'adapter/git'

require 'grit'

repo = Grit::Repo.init(File.expand_path('../test', __FILE__))
adapter = Adapter[:git].new(repo)
adapter.clear

adapter.write('foo', 'bar')
puts 'Should be bar: ' + adapter.read('foo').inspect

adapter.delete('foo')
puts 'Should be nil: ' + adapter.read('foo').inspect

adapter.write('foo', 'bar')
adapter.clear
puts 'Should be nil: ' + adapter.read('foo').inspect

puts 'Should be bar: ' + adapter.fetch('foo', 'bar')