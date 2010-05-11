require 'net/http/persistent'

##
# This stub overrides Net::HTTP::Persistent's request method to allow programs
# that use Net::HTTP::Persistent to be easily tested.
#
# == Usage
#
#   require 'rc_rest/net_http_persistent_stub'
#
#   class TestMyClass < MiniTest::Unit::TestCase
#
#     def setup
#       Net::HTTP::Persistent.responses = []
#       Net::HTTP::Persistent.uris = []
#
#       @obj = MyClass.new
#     end
#
#     def test_my_method
#       Net::HTTP::Persistent.responses << 'some text request would return'
#
#       result = @obj.my_method
#
#       assert_equal :something_meaninfgul, result
#
#       assert_equal true, Net::HTTP::Persistent.responses.empty?
#       assert_equal 1, Net::HTTP::Persistent.uris.length
#       assert_equal 'http://example.com/path', Net::HTTP::Persistent.uris.first
#     end
#
#  end

class Net::HTTP::Persistent

  class << self

    ##
    # List of responses #request should return.
    #
    # If a String is given a Net::HTTPOK is created
    #
    # If a proc is given, it is called.  The proc should raise an exception or
    # return a Net::HTTPResponse subclass.
    #
    # Unlike URI::HTTP from rc-rest 3.x and earlier you must return a
    # Net::HTTPResponse subclass.

    attr_accessor :responses

    ##
    # URIs recorded

    attr_accessor :uris

  end

  alias original_request request

  def request uri
    self.class.uris << uri.to_s
    response = self.class.responses.shift

    response = response.call if response.respond_to? :call

    return response if Net::HTTPResponse === response

    r = Net::HTTPOK.new '1.0', 200, 'OK'
    r.body = response
    r
  end

end

