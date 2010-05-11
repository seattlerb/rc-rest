require 'net/http/persistent'
require 'nokogiri'

##
# Abstract class for implementing REST APIs.
#
# === Example
#
# The following methods must be implemented in sublcasses:
#
# +initialize+:: Sets @url to the service enpoint.
# +check_error+:: Checks for errors in the server response.
# +parse_response+:: Extracts information from the server response.
#
# If you have extra URL paramaters (application id, output type) or need to
# perform URL customization, override +make_url+ and +make_multipart+.
#
#   class FakeService < RCRest
#   
#     class Error < RCRest::Error; end
#   
#     def initialize(appid)
#       @appid = appid
#       @url = URI.parse 'http://example.com/api/'
#     end
#   
#     def check_error(xml)
#       raise Error, xml.elements['error'].text if xml.elements['error']
#     end
#   
#     def make_url(method, params)
#       params[:appid] = @appid
#       super method, params
#     end
#   
#     def parse_response(xml)
#       return xml
#     end
#   
#     def test(query)
#       get :test, :q => query
#     end
#   
#   end

class RCRest

  ##
  # You are using this version of RCRest

  VERSION = '4.0'

  ##
  # Abstract Error class.

  class Error < RuntimeError; end

  ##
  # Error raised when communicating with the server

  class CommunicationError < Error

    ##
    # The original exception

    attr_accessor :original_exception

    ##
    # Creates a new CommunicationError with +message+ and +original_exception+

    def initialize(original_exception)
      @original_exception = original_exception

      message = "Communication error: #{original_exception.message}(#{original_exception.class})"
      super message
    end

  end

  ##
  # Web services initializer.
  #
  # Concrete web services implementations must set the +url+ instance
  # variable which must be a URI.

  def initialize
    raise NotImplementedError, 'need to implement #intialize and set @url'
  end

  ##
  # Must extract and raise an error from +xml+, an Nokogiri::XML::Document, if
  # any. Must return if no error could be found.

  def check_error(xml)
    raise NotImplementedError
  end

  def expand_params(params) # :nodoc:
    expanded_params = []

    params.each do |k,v|
      if v.respond_to? :each and not String === v then
        v.each { |s| expanded_params << [k, s] }
      else
        expanded_params << [k, v]
      end
    end

    expanded_params.sort_by { |k,v| [k.to_s, v.to_s] }
  end

  ##
  # Performs a GET request for method +method+ with +params+.  Calls
  # #parse_response on the concrete class with an Nokogiri::XML::Document
  # instance and returns its result.

  def get(method, params = {})
    @http ||= Net::HTTP::Persistent.new

    url = make_url method, params

    http_response = @http.request url

    case http_response
    when Net::HTTPSuccess
      res = Nokogiri::XML http_response.body, nil, nil, 0

      check_error res

      parse_response res
    when Net::HTTPMovedPermanently,
         Net::HTTPFound,
         Net::HTTPSeeOther,
         Net::HTTPTemporaryRedirect then
      # TODO
    else
      begin
        xml = Nokogiri::XML http_response.body, nil, nil, 0
        check_error xml
      rescue Nokogiri::XML::SyntaxError => e
      end

      e = CommunicationError.new http_response
      e.message << "\n\nunhandled error:\n#{xml.to_s}"

      raise e
    end
  rescue Net::HTTP::Persistent::Error, SocketError, Timeout::Error,
         Nokogiri::XML::SyntaxError => e
    raise CommunicationError.new(e)
  end

  ##
  # Creates a URI for method +method+ and a Hash of parameters +params+.
  # Override this then call super if you need to add extra params like an
  # application id, output type, etc.
  #
  # If the value of a parameter responds to #each, make_url creates a
  # key-value pair per value in the param.
  #
  # Examples:
  #
  # If the URL base is:
  #
  #   http://example.com/api/
  #
  # then:
  #
  #   make_url nil, :a => '1 2', :b => [4, 3]
  #
  # creates the URL:
  #
  #   http://example.com/api/?a=1%202&b=3&b=4
  #
  # and
  #
  #   make_url :method, :a => '1'
  #
  # creates the URL:
  #
  #   http://example.com/api/method?a=1

  def make_url(method, params = nil)
    escaped_params = expand_params(params).map do |k,v|
      k = URI.escape(k.to_s).gsub(';', '%3B').gsub('+', '%2B').gsub('&', '%26')
      v = URI.escape(v.to_s).gsub(';', '%3B').gsub('+', '%2B').gsub('&', '%26')
      "#{k}=#{v}"
    end

    query = escaped_params.join '&'

    url = @url + "./#{method}"
    url.query = query
    return url
  end

  ##
  # Creates a multipart form post for the Hash of parameters +params+.
  # Override this then call super if you need to add extra params like an
  # application id, output type, etc.
  #
  # #make_multipart handles arguments similarly to #make_url.

  def make_multipart(params)
    boundary = (0...8).map { rand(255).to_s 16 }.join '_'
    data = expand_params(params).map do |key, value|
      [ "--#{boundary}",
        "Content-Disposition: form-data; name=\"#{key}\"",
        nil,
        value]
    end

    data << "--#{boundary}--"
    return [boundary, data.join("\r\n")]
  end

  ##
  # Must parse results from +xml+, an Nokogiri::XML::Document, into something
  # sensible for the API.

  def parse_response(xml)
    raise NotImplementedError
  end

  ##
  # Performs a POST request for method +method+ with +params+.  Calls
  # #parse_response on the concrete class with an Nokogiri::XML::Document
  # instance and returns its result.

  def post(method, params = {})
    url = make_url method, params
    query = url.query
    url.query = nil

    req = Net::HTTP::Post.new url.path
    req.body = query
    req.content_type = 'application/x-www-form-urlencoded'

    res = Net::HTTP.start url.host, url.port do |http|
      http.request req
    end

    xml = Nokogiri::XML(res.body, nil, nil, 0)

    check_error xml

    parse_response xml
  rescue SystemCallError, SocketError, Timeout::Error, IOError,
         Nokogiri::XML::SyntaxError => e
    raise CommunicationError.new(e)
  rescue Net::HTTPError => e
    xml = Nokogiri::XML(e.res.body) { |cfg| cfg.strict }
    check_error xml
    raise CommunicationError.new(e)
  end

  ##
  # Performs a POST request for method +method+ with +params+, submitting a
  # multipart form.  Calls #parse_response on the concrete class with an
  # Nokogiri::XML::Document instance and returns its result.

  def post_multipart(method, params = {})
    url = make_url method, {}
    url.query = nil

    boundary, data = make_multipart params

    req = Net::HTTP::Post.new url.path
    req.content_type = "multipart/form-data; boundary=#{boundary}"
    req.body = data

    res = Net::HTTP.start url.host, url.port do |http|
      http.request req
    end

    xml = Nokogiri::XML(res.body, nil, nil, 0)

    check_error xml

    parse_response xml
  rescue SystemCallError, SocketError, Timeout::Error, IOError,
         Nokogiri::XML::SyntaxError => e
    raise CommunicationError.new(e)
  rescue Net::HTTPError => e
    xml = Nokogiri::XML(e.res.body, nil, nil, 0)
    check_error xml
    raise CommunicationError.new(e)
  end

end

