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
  gem 'nokogiri', :require => nil
  
  gem 'test-unit', '~> 2.5', :require => nil # for Rails < 4.0 due "sanity"
  gem 'minitest', :require => nil # Rails 4.x (quite picky about version)
end