
module RequestExceptionHandler

  @@parse_request_parameters_exception_handler = lambda do |request, exception|
    Thread.current[:request_exception] = exception
    request_body = request.respond_to?(:body) ? request.body : request.raw_post

    logger = defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new($stderr)
    if logger.info?
      content_log = request_body
      if request_body.is_a?(StringIO)
        pos = request_body.pos
        content_log = request_body.read
      end
      logger.info "#{exception.class.name} occurred while parsing request parameters." +
                  "\nContents:\n#{content_log}\n"
      request_body.pos = pos if pos
    end
              
    content_type = if request.respond_to?(:content_type_with_parameters)
      request.send :content_type_with_parameters # AbstractRequest
    else # rack request
      request.respond_to?(:content_mime_type) ? request.content_mime_type : request.content_type
    end
    { "body" => request_body, "content_type" => content_type, "content_length" => request.content_length }
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
