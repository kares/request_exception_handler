
module RequestExceptionHandler

  @@parse_request_parameters_exception_handler = lambda do |request, exception|
    Thread.current[:request_exception] = exception
    logger = defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new($stderr)
    logger.info "#{exception.class.name} occurred while parsing request parameters." +
                "\nContents:\n\n#{request.raw_post}"
              
    content_type = if request.respond_to?(:content_type_with_parameters)
      request.send :content_type_with_parameters # AbstractRequest
    else
      request.content_type # rack request
    end
    { "body" => request.respond_to?(:body) ? request.body : request.raw_post,
      "content_type" => content_type,
      "content_length" => request.content_length }
  end
  
  mattr_accessor :parse_request_parameters_exception_handler

  def self.reset_request_exception
    Thread.current[:request_exception] = nil
  end

  def self.included(base)
    base.prepend_before_filter :check_request_exception
  end

  def check_request_exception
    e = request_exception
    raise e if e && e.is_a?(Exception)
  end

  def request_exception
    return @_request_exception if defined? @_request_exception
    @_request_exception = Thread.current[:request_exception]
    RequestExceptionHandler.reset_request_exception
    @_request_exception
  end

end
