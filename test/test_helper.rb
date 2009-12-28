require 'rubygems'
require 'test/unit'

# enable testing with different version of rails via argv :
# ruby request_exception_handler_test.rb RAILS_VERSION=2.2.2
if ARGV.find { |opt| /RAILS_VERSION=([\d\.]+)/ =~ opt }
  RAILS_VERSION = $~[1]
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
require 'action_controller/integration'
require 'action_controller/session_management'

# Make double-sure the RAILS_ENV is set to test,
# so fixtures are loaded to the right database
silence_warnings { RAILS_ENV = "test" }

module Rails # a minimal Rails - to suffice the plugin
  class << self

    def initialized?
      @initialized || false
    end

    def initialized=(initialized)
      @initialized ||= initialized
    end

    def logger
      if defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      else
        # NOTE: can not return nil as Rails does (at least in 2.3.4)
        # some parts we test expect the logger to be not nil !
        # action_controller/params_parser#parse_formatted_parameters
        Logger.new($stdout) # nil
      end
    end

    def root
      Pathname.new(RAILS_ROOT) if defined?(RAILS_ROOT)
    end

    def env
      ActiveSupport::StringInquirer.new(RAILS_ENV)
    end

    def version
      Rails::VERSION::STRING
    end
    
  end
end

require 'rails/version'
puts "emulating Rails.version = #{Rails.version}"

skey = Rails.version < '2.3' ? :session_key : :key
ActionController::Base.session_options[skey] = '_request_exception_handler_test'
ActionController::Base.session_options[:secret] = 'x' * 30

# call the plugin's init.rb - thus it's setup as it would in a rails app :
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../lib')
require File.join(File.dirname(__FILE__), '../init')
