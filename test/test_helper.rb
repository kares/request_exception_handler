require 'rubygems'
require 'bundler/setup' rescue nil

# enable testing with different version of rails via argv :
# ruby request_exception_handler_test.rb RAILS_VERSION=2.3.18
version =
  if ARGV.find { |opt| /RAILS_VERSION=([\d\.]+)/ =~ opt }
    $~[1]
  else
    ENV['RAILS_VERSION'] # rake test RAILS_VERSION=3.2.18
  end

if version
  RAILS_VERSION = version
  gem 'activesupport', "#{RAILS_VERSION}"
  gem 'actionpack', "#{RAILS_VERSION}"
  gem 'rails', "#{RAILS_VERSION}"
else
  gem 'activesupport'
  gem 'actionpack'
  gem 'rails'
end unless defined? Bundler

require 'rails/version'
puts "emulating Rails.version = #{Rails::VERSION::STRING}"

if Rails::VERSION::MAJOR < 4
  gem 'test-unit' rescue nil
  begin
    require 'test/unit'
  rescue LoadError
    gem 'minitest'
    require 'minitest/unit'
    MiniTest::Unit.autorun
  end
else
  gem 'minitest'
end

begin
  require 'iconv'
rescue LoadError
  begin
    require 'active_support/inflector'
  rescue LoadError
    $LOADED_FEATURES << 'iconv.rb'
    require 'active_support/inflector'
  end
end if Rails::VERSION::MAJOR < 3
require 'active_support'
require 'active_support/test_case'
require 'action_controller'
require 'action_controller/test_case'

require 'action_controller/integration' if Rails::VERSION::MAJOR < 3
require 'action_controller/session_management' if Rails::VERSION::MAJOR < 3
require 'action_dispatch' if Rails::VERSION::MAJOR >= 3
require 'action_dispatch/routing' if Rails::VERSION::MAJOR >= 3

begin
  require 'action_dispatch/testing/integration'
  IntegrationTest = ActionDispatch::IntegrationTest
rescue LoadError
  IntegrationTest = ActionController::IntegrationTest
end

if Rails::VERSION::MAJOR >= 3
  ActiveSupport::Deprecation.behavior = :stderr
else
  ActiveSupport::Deprecation.debug = true
end

if Rails::VERSION::MAJOR >= 4
  require 'rails'
  # a minimal require 'rails/all' :
  require 'action_controller/railtie'
  require 'rails/test_help'
elsif Rails::VERSION::MAJOR >= 3
  require 'rails'
  # a minimal require 'rails/all' :
  require 'action_controller/railtie'
  require 'rails/test_unit/railtie'
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
silence_warnings { RAILS_ENV = 'test' }

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

    class Application < Rails::Application; end

    Application.configure do
      if config.respond_to?(:secret_key_base=)
        config.secret_key_base = 'x' * 30
      else
        config.secret_token = 'x' * 30
      end
      config.cache_classes = true if config.respond_to?(:cache_classes=)
      config.eager_load = false if config.respond_to?(:eager_load=)
      config.action_controller.allow_forgery_protection = false
      config.active_support.deprecation = :stderr
    end

    # Since 4.0 only DEFAULT_PARSERS = { Mime::JSON => :json } is setup by default
    unless ActionDispatch::ParamsParser::DEFAULT_PARSERS[ Mime::XML ]
      ActionDispatch::ParamsParser::DEFAULT_PARSERS[ Mime::XML ] = Proc.new do
        |raw_post| ( Hash.from_xml(raw_post) || {} ).with_indifferent_access
      end
    end if defined? ActionDispatch::ParamsParser::DEFAULT_PARSERS

    Application.initialize!

  end

end

$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'request_exception_handler'
