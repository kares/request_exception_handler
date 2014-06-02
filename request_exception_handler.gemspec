Gem::Specification.new do |gem|
  gem.name        = "request_exception_handler"
  gem.version     = '0.5.0'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Karol Bucek"]
  gem.email       = ["self@kares.org"]
  gem.homepage    = "http://github.com/kares/request_exception_handler"
  gem.summary     = "a handler for all request (parsing) related exceptions"
  gem.description = "rails hook that allows one to handle request parameter parsing exceptions (e.g. invalid JSON) with a rescue block"
  gem.licenses    = ['Apache-2.0']

  gem.files        = Dir.glob("lib/*") + %w( LICENSE README.md Rakefile )
  gem.require_path = 'lib'
  gem.test_files   = Dir.glob("test/*.rb")

  gem.add_dependency 'actionpack', '>= 2.1'
  gem.add_development_dependency 'rake', '~> 10.3.2'

  gem.extra_rdoc_files = [ "README.md" ]
  gem.rubyforge_project = '[none]'
end