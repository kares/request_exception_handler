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
