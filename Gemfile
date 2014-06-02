source 'https://rubygems.org'
# Specify your gem's dependencies in test-unit-context.gemspec
gemspec

# RAILS_VERSION=3.2.18 bundle update rails
rails_version = ENV['RAILS_VERSION'] || ''
unless rails_version.empty?
  gem 'rails', rails_version
else
  gem 'rails'
end

group :test do
  if RUBY_VERSION > '1.9.0'
    gem 'nokogiri', :require => nil
  else
    gem 'nokogiri', '< 1.6', :require => nil
  end

  gem 'test-unit', '~> 2.5', :require => nil # for Rails < 4.0 due "sanity"
  gem 'minitest', :require => nil # Rails 4.x (quite picky about version)
end