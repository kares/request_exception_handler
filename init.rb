require 'request_exception_handler'
ActionController::Base.send :include, RequestExceptionHandler

# NOTE: Rails 2.x monkey patching follows :

if defined? ActionController::ParamsParser # Rails 2.3.x

  ActionController::ParamsParser.class_eval do

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

    alias_method_chain :parse_formatted_parameters, :exception_handler

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
