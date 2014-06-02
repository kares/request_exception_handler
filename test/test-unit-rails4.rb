# mock require 'active_support/testing/autorun'
$LOADED_FEATURES << 'active_support/testing/autorun.rb'
require 'test-unit'
##

# mock require 'active_support/test_case'
$LOADED_FEATURES << 'active_support/test_case.rb'

require 'active_support/testing/tagged_logging'
require 'active_support/testing/setup_and_teardown' # ?
require 'active_support/testing/assertions'
require 'active_support/testing/deprecation'
#require 'active_support/testing/pending'
#require 'active_support/testing/declarative'
#require 'active_support/testing/isolation'
require 'active_support/testing/constant_lookup'
require 'active_support/core_ext/kernel/reporting'
require 'active_support/deprecation'

#begin
#  silence_warnings { require 'mocha/setup' }
#rescue LoadError
#end

module ActiveSupport
  class TestCase < Test::Unit::TestCase
    Assertion = Test::Unit::Assertions

    @@tags = {}
    def self.for_tag(tag)
      yield if @@tags[tag]
    end

    include ActiveSupport::Testing::TaggedLogging
    include ActiveSupport::Testing::SetupAndTeardown
    include ActiveSupport::Testing::Assertions
    include ActiveSupport::Testing::Deprecation
    #include ActiveSupport::Testing::Pending
    #extend ActiveSupport::Testing::Declarative

    # Fails if the block raises an exception.
    #
    # assert_nothing_raised do
    # ...
    # end
    #def assert_nothing_raised(*args)
    #  yield
    #end
  end
end

##

#require "test/unit/active_support"
#require "test/unit/notify"
#require "test/unit/rr"