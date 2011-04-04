require 'rubygems'
require 'test/unit'

# enable testing with different version of rails via argv :
# ruby request_exception_handler_test.rb RAILS_VERSION=2.2.2

version =
  if ARGV.find { |opt| /RAILS_VERSION=([\d\.]+)/ =~ opt }
    $~[1]
  else
    # rake test RAILS_VERSION=2.3.5
    ENV['RAILS_VERSION']
  end

if version
  RAILS_VERSION = version
  gem 'activesupport', "= #{RAILS_VERSION}"
  gem 'activerecord', "= #{RAILS_VERSION}"
  gem 'actionpack', "= #{RAILS_VERSION}"
  gem 'actionmailer', "= #{RAILS_VERSION}"
  gem 'rails', "= #{RAILS_VERSION}"
else
  gem 'activesupport'
  gem 'activerecord'
  gem 'actionpack'
  gem 'actionmailer'
  gem 'rails'
end

require 'active_support'
require 'active_support/test_case'
require 'action_controller'
require 'action_controller/test_case'

require 'rails/version'
puts "emulating Rails.version = #{version = Rails::VERSION::STRING}"

require 'action_controller/integration' if version < '3.0.0'
require 'action_controller/session_management' if version < '3.0.0'
require 'action_dispatch' if version >= '3.0.0'
require 'action_dispatch/routing' if version >= '3.0.0'

if version >= '3.0.0'
  require 'rails'
  require 'rails/all'
  require 'rails/test_help'
else
  module Rails
    class << self
      
      def initialized?
        @initialized || false
      end

      def initialized=(initialized)
        @initialized ||= initialized
      end

      def backtrace_cleaner
        @@backtrace_cleaner ||=
          begin
            require 'rails/gem_dependency' # backtrace_cleaner depends on this !
            require 'rails/backtrace_cleaner'
            Rails::BacktraceCleaner.new
          rescue LoadError
            nil
          end
      end

      def root
        require 'pathname'
        Pathname.new(RAILS_ROOT)
      end

      def env
        @_env ||= ActiveSupport::StringInquirer.new(RAILS_ENV)
      end

      def cache
        RAILS_CACHE
      end

      def version
        VERSION::STRING
      end

      def public_path
        @@public_path ||= self.root ? File.join(self.root, "public") : "public"
      end

      def public_path=(path)
        @@public_path = path
      end
      
    end
  end
end

silence_warnings { RAILS_ROOT = File.expand_path( File.dirname(__FILE__) ) }

# Make double-sure the RAILS_ENV is set to test,
# so fixtures are loaded to the right database
silence_warnings { RAILS_ENV = "test" }

Rails.backtrace_cleaner.remove_silencers! if Rails.backtrace_cleaner

module Rails # make sure we can set the logger
  class << self
    attr_accessor :logger
  end
end

File.open(File.join(File.dirname(__FILE__), 'test.log'), 'w') do |file|
  Rails.logger = Logger.new(file.path)
end

if ActionController::Base.respond_to? :session_options # Rails 2.x

  skey = Rails.version < '2.3' ? :session_key : :key
  ActionController::Base.session_options[skey] = '_request_exception_handler_test'
  ActionController::Base.session_options[:secret] = 'x' * 30

else # since Rails 3.0.0 :
  
  module RequestExceptionHandlerTest
    class Application < Rails::Application
      config.secret_token = 'x' * 30
    end
  end
  
  # Initialize the rails application
  RequestExceptionHandlerTest::Application.initialize!

end

ActiveSupport::TestCase.class_eval do

  def setup_fixtures
    return nil # Rails 3 load hooks !
  end
  
end

# call the plugin's init.rb - thus it's setup as it would in a rails app :
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../lib')
require File.join(File.dirname(__FILE__), '../init')
