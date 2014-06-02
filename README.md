# RequestExceptionHandler

Rails is not capable of calling your exception handlers when an error occurs
during the parsing of request parameters (e.g. in case of invalid JSON body).

This will hopefully change someday, but until then I have created this delicate
monkey-patch for the request parameter parser to allow more flexibility when
an invalid request body is received.

Tested on 4.x and 3.x but it should still work on Rails 2.3 and 2.2.3 as well.

[![Build Status][0]](http://travis-ci.org/#!/kares/request_exception_handler)

## Install

    gem 'request_exception_handler'

~~or as a plain-old (obsolete) rails plugin~~ :

    script/plugin install git://github.com/kares/request_exception_handler.git

## Example

The code hooks into parameter parsing and allows a request to be constructed
even if the parsing of the submitted raw content fails (JSON/XML backend raises
a parse error). A before filter is installed that checks for a request exception
and re-raises, it thus it seems to Rails that the exception comes from the
application code and is processed as all other "business" exceptions.

One might skip this "request-exception" filter (e.g. per action - the usual way)
and install another to handle such cases (it's good to make sure the filter gets
at the beginning of the chain) :

```ruby
class MyController < ApplicationController

  skip_before_filter :check_request_exception # filter the plugin installed

  # custom before filter use request_exception to detect occured errors
  prepend_before_filter :return_409_on_json_errors

  private
  def return_409_on_json_errors
    if e = request_exception && e.is_a?(ActiveSupport::JSON::ParseError)
      head 409
    else
      head 500
    end
  end

end
```

Another option of how to modify the returned 500 status is to use exception
handlers the same way you're (hopefully) using them for your own exceptions :

```ruby
class ApplicationController < ActionController::Base

  rescue_from 'REXML::ParseException' do |exception|
    render :text => exception.to_s, :status => 422
  end

end
```

If you're not using REXML as a parsing backend the exception might vary, e.g.
for Nokogiri the rescue block would look something like :

```ruby
rescue_from 'Nokogiri::XML::SyntaxError' do |exception|
  render :text => exception.to_s, :status => 422
end
```

## Copyright

Copyright (c) 2014 [Karol Bucek](https://github.com/kares).
See LICENSE (http://www.apache.org/licenses/LICENSE-2.0) for details.

[0]: https://secure.travis-ci.org/kares/request_exception_handler.png