# The mixin that provides the +request_exception+
# by default included into +ActionController::Base+
module RequestExceptionHandler

  THREAD_LOCAL_NAME = :_request_exception

  @@parse_request_parameters_exception_handler = lambda do |request, exception|
    RequestExceptionHandler.store_request_exception(exception)
    request_body = request.respond_to?(:body) ? request.body : request.raw_post

    logger = RequestExceptionHandler.logger
    if logger.debug?
      content_log = request_body
      if request_body.is_a?(StringIO)
        pos = request_body.pos
        content_log = request_body.read
      end
      logger.debug "#{exception.class.name} occurred while parsing request parameters." <<
                   "\nContents:\n#{content_log}\n"
      request_body.pos = pos if pos
    elsif logger.info?
      logger.info "#{exception.class.name} occurred while parsing request parameters."
    end

    content_type = if request.respond_to?(:content_mime_type)
      request.content_mime_type
    elsif request.respond_to?(:content_type_with_parameters)
      request.send :content_type_with_parameters # (legacy) ActionController::AbstractRequest
    else
      request.content_type
    end
    { "body" => request_body, "content_type" => content_type, "content_length" => request.content_length }
  end

  begin
    mattr_accessor :parse_request_parameters_exception_handler
  rescue NoMethodError => e
    require('active_support/core_ext/module/attribute_accessors') && retry
    raise e
  end

  @@parse_request_parameters_exception_logger = nil

  # Retrieves the Rails logger.
  def self.logger
    @@parse_request_parameters_exception_logger ||=
      defined?(Rails.logger) ? Rails.logger :
        defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER :
          Logger.new(STDERR)
  end

  def self.included(base)
    base.prepend_before_filter :check_request_exception
  end

  # Resets the current +request_exception+ (to nil).
  def self.reset_request_exception
    store_request_exception nil
  end

  if defined? Thread.current.thread_variables

    # Resets the current +request_exception+ (to nil).
    def self.store_request_exception(exception)
      Thread.current.thread_variable_set THREAD_LOCAL_NAME, exception
    end

    # Retrieves and keeps track of the current request exception if any.
    def request_exception
      return @_request_exception if defined? @_request_exception
      @_request_exception = Thread.current.thread_variable_get(THREAD_LOCAL_NAME)
      RequestExceptionHandler.reset_request_exception
      @_request_exception
    end

  else

    # Resets the current +request_exception+ (to nil).
    def self.store_request_exception(exception)
      Thread.current[THREAD_LOCAL_NAME] = exception
    end

    # Retrieves and keeps track of the current request exception if any.
    def request_exception
      return @_request_exception if defined? @_request_exception
      @_request_exception = Thread.current[THREAD_LOCAL_NAME]
      RequestExceptionHandler.reset_request_exception
      @_request_exception
    end

  end

  # Checks and raises a +request_exception+ (gets prepended as a before filter).
  def check_request_exception
    if e = request_exception
      raise e if e.is_a?(Exception)
    end
  end

end

require 'action_controller/base'
ActionController::Base.send :include, RequestExceptionHandler

# NOTE: Rails "parameters-parser" monkey patching follows :

if defined? ActionDispatch::ParamsParser::ParseError # Rails 4.x

  class ActionDispatch::ParamsParser

    alias_method 'parse_formatted_parameters_without_exception_handler', 'parse_formatted_parameters'

    def parse_formatted_parameters_with_exception_handler(env)
      begin
        out = parse_formatted_parameters_without_exception_handler(env)
        RequestExceptionHandler.reset_request_exception # make sure it's nil
        out
      rescue ParseError => e
        e = e.original_exception
        handler = RequestExceptionHandler.parse_request_parameters_exception_handler
        handler ? handler.call(ActionDispatch::Request.new(env), e) : raise
      rescue => e # all Exception-s get wrapped into ParseError ... but just in case
        handler = RequestExceptionHandler.parse_request_parameters_exception_handler
        handler ? handler.call(ActionDispatch::Request.new(env), e) : raise
      end
    end

    alias_method 'parse_formatted_parameters', 'parse_formatted_parameters_with_exception_handler'

  end

elsif defined? ActionDispatch::ParamsParser # Rails 3.x

  class ActionDispatch::ParamsParser

    def parse_formatted_parameters_with_exception_handler(env)
      begin
        out = parse_formatted_parameters_without_exception_handler(env)
        RequestExceptionHandler.reset_request_exception # make sure it's nil
        out
      rescue Exception => e # YAML, XML or Ruby code block errors
        handler = RequestExceptionHandler.parse_request_parameters_exception_handler
        handler ? handler.call(ActionDispatch::Request.new(env), e) : raise
      end
    end

    alias_method_chain 'parse_formatted_parameters', 'exception_handler'

  end

elsif defined? ActionController::ParamsParser # Rails 2.3.x

  class ActionController::ParamsParser

    def parse_formatted_parameters_with_exception_handler(env)
      begin
        out = parse_formatted_parameters_without_exception_handler(env)
        RequestExceptionHandler.reset_request_exception # make sure it's nil
        out
      rescue Exception => e # YAML, XML or Ruby code block errors
        handler = RequestExceptionHandler.parse_request_parameters_exception_handler
        handler ? handler.call(ActionController::Request.new(env), e) : raise
      end
    end

    alias_method_chain 'parse_formatted_parameters', 'exception_handler'

  end

else # old-style Rails < 2.3

  ActionController::AbstractRequest.class_eval do

    def parse_formatted_request_parameters_with_exception_handler
      begin
        out = parse_formatted_request_parameters_without_exception_handler
        RequestExceptionHandler.reset_request_exception # make sure it's nil
        out
      rescue Exception => e # YAML, XML or Ruby code block errors
        handler = RequestExceptionHandler.parse_request_parameters_exception_handler
        handler ? handler.call(self, e) : raise
      end
    end

    alias_method_chain :parse_formatted_request_parameters, :exception_handler

  end

end
