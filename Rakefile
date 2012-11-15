#!/usr/bin/env rake

desc 'Default: run unit tests.'
task :default => :test

require 'rake/testtask'
desc 'Test the request_exception_handler plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

begin
  require 'bundler/gem_helper'
  Bundler::GemHelper.class_eval { def version_tag; "#{version}"; end }
  require 'bundler/gem_tasks'
rescue LoadError
end