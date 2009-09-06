require 'test_helper'

class RequestExceptionHandlerTest < ActionController::IntegrationTest

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

  ###

  test "parse valid json" do
    with_test_routing do
      post "/parse", "{\"cicinbrus\": {\"name\": \"Ferko\"}}", 'CONTENT_TYPE' => 'application/json'
      assert_response 200
    end
  end

  test "parse invalid json returns 500 by default" do
    with_test_routing do
      post "/parse", "{\"cicinbrus\": {\"name\": \"Ferko\"}", 'CONTENT_TYPE' => 'application/json'
      assert_response 500
    end
  end

  ###

  test "parse valid xml" do
    with_test_routing do
      post "/parse", "<cicinbrus> <name>Ferko</name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
      assert_response 200
    end
  end

  test "parse invalid xml returns 500 by default" do
    with_test_routing do
      post "/parse", "<cicinbrus> <name>Ferko<name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
      assert_response 500
    end
  end

  ###

  test "controller responds to request_exception and returns nil on valid request" do
    with_test_routing do
      post "/parse"
      assert controller.respond_to? :request_exception
      assert_nil controller.request_exception
    end
  end

  test "controller returns nil on request_exception with check_request_exception skipped" do
    with_test_routing do
      post "/parse_with_check_request_exception_skipped"
      assert_nil controller.request_exception
    end
  end

  test "request exception returns parse exception on invalid xml request" do
    with_test_routing do
      post "/parse", "<cicinbrus> <name>Ferko</namee> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
      assert_not_nil controller.request_exception
      assert_instance_of REXML::ParseException, controller.request_exception
    end
  end

  test "request exception returns parse exception on invalid json request" do
    with_test_routing do
      post "/parse", "{\"cicinbrus\": {\"name: \"Ferko\"}}", 'CONTENT_TYPE' => 'application/json'
      assert_not_nil controller.request_exception
      assert_instance_of ActiveSupport::JSON::ParseError, controller.request_exception
    end
  end

  test "request exception gets cleared for another valid request" do
    with_test_routing do
      post "/parse", "<cicinbrus> <name>Ferko</name> </cicinbrus ", 'CONTENT_TYPE' => 'application/xml'
      post "/parse", "<cicinbrus> <name>Ferko</name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
      assert_nil controller.request_exception
    end
  end

  test "request exception gets cleared for another valid request with check_request_exception skipped" do
    with_test_routing do
      post "/parse_with_check_request_exception_skipped",
           "<cicinbrus> <name>Ferko</name> </cicinbrus ", 'CONTENT_TYPE' => 'application/xml'
      post "/parse_with_check_request_exception_skipped",
           "<cicinbrus> <name>Ferko</name> </cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
      assert_nil controller.request_exception
    end
  end

  test "parse with check_request_exception skipped does not re-raise parse exception" do
    with_test_routing do
      post "/parse_with_check_request_exception_skipped",
           "<cicinbrus> <name>Ferko</name> </cicinbrus ", 'CONTENT_TYPE' => 'application/xml'
      assert_response 200
      assert_not_nil controller.request_exception
    end
  end

  test "parse with check_request_exception replaced does return 501 on parse exception" do
    with_test_routing do
      post "/parse_with_check_request_exception_replaced",
           "<cicinbrus> <name>Ferko</name> <cicinbrus>", 'CONTENT_TYPE' => 'application/xml'
      assert_response 501
    end
  end

  test "on parse error custom rescue handler gets called" do
    begin
      rescue_handlers = TestController.rescue_handlers.dup
      TestController.rescue_from 'REXML::ParseException' do |exception|
        render :text => exception.class.name, :status => 505
      end

      with_test_routing do
        post "/parse", "<cicinbrus> <name>Ferko</name>", 'CONTENT_TYPE' => 'application/xml'
        assert_response 505
      end
    ensure
      TestController.rescue_handlers.replace(rescue_handlers)
    end
  end

  private

  def with_test_routing
    with_routing do |set|
      set.draw do |map|
        map.connect ':action', :controller => "request_exception_handler_test/test"
      end
      yield
    end
  end

end
