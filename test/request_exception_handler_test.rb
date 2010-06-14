require File.join(File.dirname(__FILE__), 'test_helper')

#
# NOTE: due to the test_helper.rb argument parsing this test might
#       be run with different versions of Rails e.g. :
# 
# ruby request_exception_handler_test.rb RAILS_VERSION=2.1.2
#

class TestController < ActionController::Base

  def parse
    head :ok
  end

  def parse_with_check_request_exception_skipped
    head :ok
  end

  skip_before_filter :check_request_exception, :only =>
    [ :parse_with_check_request_exception_skipped, :parse_with_check_request_exception_replaced ]

  def parse_with_check_request_exception_replaced
    head :ok
  end

  before_filter :return_501_on_request_exception, :only => [ :parse_with_check_request_exception_replaced ]

  def return_501_on_request_exception
    head 501 if request_exception
  end

end

ActionController::Routing::Routes.draw do |map|
    map.connect '/:action', :controller => "test"
end

class RequestExceptionHandlerTest < ActionController::IntegrationTest

#  def test_show_session_options
#    with_test_routing do
#
#      env = {}
#      content = '{"object": {}}'
#
#      env.update(
#        "REQUEST_METHOD" => 'POST',
#        "REQUEST_URI"    => '/parse',
#        "HTTP_HOST"      => 'test.host',
#        "REMOTE_ADDR"    => '127.0.0.1',
#        "SERVER_PORT"    => '80',
#        "CONTENT_TYPE"   => "application/json",
#        "CONTENT_LENGTH" => content.length.to_s,
#        #"HTTP_COOKIE"    => encode_cookies,
#        "HTTPS"          => "off",
#        "HTTP_ACCEPT"    => "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
#      )
#
#      data = content #"#{CGI.escape(nil)}=#{CGI.escape(content.to_s)}"
#      env['rack.input'] = data.is_a?(IO) ? data : StringIO.new(data || '')
#
#      #status, headers, result_body = ActionController::Dispatcher.new.mark_as_test_request!.call(env)
#
#      request = ActionController::RackRequest.new(env)
#      response = ActionController::RackResponse.new(request)
#      controller = ActionController::Routing::Routes.recognize(request)
#      puts request.session_options.inspect
#      controller.process(request, response) #.out(output)
#
#    end
#  end

  def test_parse_valid_json
    post "/parse", "{\"cicinbrus\": {\"name\": \"Ferko\"}}", 'CONTENT_TYPE' => 'application/json'
    assert_response 200
  end

  def test_parse_invalid_json_returns_500_by_default
    post "/parse", "{\"cicinbrus\": {\"name\": \"Ferko\"}", 'CONTENT_TYPE' => 'application/json'
    assert_response 500
  end

  ###

  def test_parse_valid_xml
    post "/parse", "<cicinbrus> <name>Ferko</name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
    assert_response 200
  end
  
  def test_parse_invalid_xml_returns_500_by_default
    post "/parse", "<cicinbrus> <name>Ferko<name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
    assert_response 500
  end

  ###

  def test_controller_responds_to_request_exception_and_returns_nil_on_valid_request
    post "/parse"
    assert controller.respond_to? :request_exception
    assert_nil controller.request_exception
  end

  def test_controller_returns_nil_on_request_exception_with_check_request_exception_skipped
    post "/parse_with_check_request_exception_skipped"
    assert_nil controller.request_exception
  end

  def test_request_exception_returns_parse_exception_on_invalid_xml_request
    post "/parse", "<cicinbrus> <name>Ferko</namee> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
    assert_not_nil controller.request_exception
    assert_xml_parse_exception controller.request_exception
  end

  def test_request_exception_returns_parse_exception_on_invalid_json_request
    post "/parse", "{\"cicinbrus\": {\"name: \"Ferko\"}}", 'CONTENT_TYPE' => 'application/json'
    assert_not_nil controller.request_exception
    assert_json_parse_exception controller.request_exception
  end

  def test_request_exception_gets_cleared_for_another_valid_request
    post "/parse", "<cicinbrus> <name>Ferko</name> </cicinbrus ", 'CONTENT_TYPE' => 'application/xml'
    post "/parse", "<cicinbrus> <name>Ferko</name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'

    #session = self.instance_variable_get(:@integration_session)
    #request = session.instance_variable_get(:@request)
    #routes = ActionController::Routing::Routes
    #path = request.path
    #puts 'path = ' + path.inspect
    #reg_env = routes.extract_request_environment(request)
    #puts 'env = ' + reg_env.inspect
    #params = routes.recognize_path(request.path, req_env)
    #routes.routes.each do |route|
    #  result = route.recognize('/test/parse/10', reg_env) #and return result
    #  puts "#{route} = #{result.inspect}"
    #end
    #request.path_parameters = params.with_indifferent_access
    #"#{params[:controller].camelize}Controller".constantize

    assert_nil controller.request_exception
  end

  def test_request_exception_gets_cleared_for_another_valid_request_with_check_request_exception_skipped
    post "/parse_with_check_request_exception_skipped",
         "<cicinbrus> <name>Ferko</name> </cicinbrus ", 'CONTENT_TYPE' => 'application/xml'
    post "/parse_with_check_request_exception_skipped",
         "<cicinbrus> <name>Ferko</name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
    assert_nil controller.request_exception
  end

  def test_parse_with_check_request_exception_skipped_does_not_reraise_parse_exception
    post "/parse_with_check_request_exception_skipped",
         "<cicinbrus> <name>Ferko</name> </cicinbrus ", 'CONTENT_TYPE' => 'application/xml'

    assert_not_nil controller.request_exception
    assert_response 200
  end

  def test_parse_with_check_request_exception_replaced_does_return_501_on_parse_exception
    post "/parse_with_check_request_exception_replaced",
         "<cicinbrus> <name>Ferko</name> <cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
    assert_response 501
  end

  def test_on_parse_error_custom_rescue_handler_gets_called
    rescue_handlers = TestController.rescue_handlers.dup
    begin
      TestController.rescue_from 'REXML::ParseException' do |exception|
        render :text => exception.class.name, :status => 505
      end

      #with_test_routing do
        post "/parse", "<cicinbrus> <name>Ferko</name>", 'CONTENT_TYPE' => 'application/xml'
        assert_response 505
      #end
    ensure
      TestController.rescue_handlers.replace(rescue_handlers)
    end
  end

  private

    def assert_xml_parse_exception(error)
      assert_instance_of REXML::ParseException, error
    end

    def assert_json_parse_exception(error)
      if ActiveSupport::JSON.respond_to?(:parse_error) # 2.3.5
        parse_error_class = ActiveSupport::JSON.parse_error
        assert_instance_of parse_error_class, error
      else
        assert_instance_of ActiveSupport::JSON::ParseError, error
      end
    end

end
