RequestExceptionHandler
=======================

Rails is not capable of calling Your exception handlers when an error occurs
during the parsing of request parameters (e.g. in case of invalid XML body).

This will hopefully change someday, but until then I have created this biutiful 
monkey-patch for request parameter parsing to allow more flexibility when
an invalid request body is received.

Code has been tested on 2.3, 2.2.3 and 2.1 as well as on Rails 3.0 / 3.1.


Install
=======

    gem 'request_exception_handler'

or as a plain-old rails plugin :

    script/plugin install git://github.com/kares/request_exception_handler.git

Example
=======

The code hooks into parameter parsing and allows a request to be constructed 
even if the params can not be parsed from the submitted raw content. A before 
filter is installed that checks for a request exception and re-raises it thus 
it seems to Rails that the exception comes from the application code and is 
processed as all other "business" exceptions. 
You might skip this filter and install Your own to handle such cases (it's good 
to make sure the filter gets to the beginning of the chain) :

    class MyController < ApplicationController

      skip_before_filter :check_request_exception # filter the plugin installed

      # custom before filter use request_exception to detect occured errors
      prepend_before_filter :return_409_on_json_errors

      private

        def return_409_on_json_errors
          if re = request_exception && re.is_a?(ActiveSupport::JSON::ParseError)
            head 409
          else
            head 500
          end
        end

    end

Another option of how to modify the returned 500 status is to use exception
handlers the same way You're (hopefully) using them for Your own exceptions :

    class ApplicationController < ActionController::Base

      rescue_from 'REXML::ParseException' do |exception|
        render :text => exception.to_s, :status => 422
      end

    end

If You're not using REXML as a parsing backend the exception might vary, e.g.
for Nokogiri the rescue block would look something like :

    rescue_from 'Nokogiri::XML::SyntaxError' do |exception|
      render :text => exception.to_s, :status => 422
    end
