Gem::Specification.new do |s|
  s.name        = "request_exception_handler"
  s.version     = '0.3'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Karol Bucek"]
  s.email       = ["self@kares.org"]
  s.homepage    = "http://github.com/kares/request_exception_handler"
  s.summary     = "handler for all the request (parsing) related exceptions"
  s.description = "a rails hook that allows one to handle request parameter parsing exceptions (invalid XML, JSON) with a rescue block"
 
  s.files        = Dir.glob("lib/*") + %w( LICENSE README.md Rakefile )
  s.require_path = 'lib'
  s.test_files   = Dir.glob("test/*.rb")
 
  s.add_dependency 'actionpack', '>= 2.1'
  
  s.extra_rdoc_files = [ "README.md" ]
  s.rubyforge_project = '[none]'
end