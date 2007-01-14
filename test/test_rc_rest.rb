require 'test/unit'
require 'rubygems'
require 'test/zentest_assertions'
require 'rc_rest/uri_stub'
require 'rc_rest/net_http_stub'
require 'rc_rest'

class FakeService < RCRest

  class Error < RCRest::Error; end

  def initialize
    @url = URI.parse 'http://example.com/test'
  end

  def check_error(xml)
    raise Error, xml.elements['error'].text if xml.elements['error']
  end

  def do_get
    get :method
  end

  def do_post
    post :method, :param => 'value'
  end

  def do_post_multipart
    post_multipart :method, :param => 'value'
  end

  def parse_response(xml)
    return xml
  end

end

class TestFakeService < Test::Unit::TestCase

  def setup
    URI::HTTP.responses = []
    URI::HTTP.uris = []

    Net::HTTP.params = []
    Net::HTTP.paths = []
    Net::HTTP.responses = []

    @fs = FakeService.new

    srand 0
  end

  def test_check_error
    xml = REXML::Document.new '<error>you broked it</error>'
    @fs.check_error xml

  rescue FakeService::Error => e
    assert_equal 'you broked it', e.message

  else
    flunk 'expected an error'
  end

  def test_do_get
    xml = '<result>stuff</result>'
    URI::HTTP.responses << xml

    result = @fs.do_get

    assert_equal xml, result.to_s
    assert_equal 'http://example.com/method?', URI::HTTP.uris.first
  end

  def test_do_get_error_400
    URI::HTTP.responses << proc do
      xml = '<error>you did the bad thing</error>'
      raise OpenURI::HTTPError.new('400 Bad Request', StringIO.new(xml))
    end

    assert_raise FakeService::Error do @fs.do_get end
  end

  def test_do_get_error_unhandled
    URI::HTTP.responses << proc do
      xml = '<other_error>you did the bad thing</other_error>'
      raise OpenURI::HTTPError.new('500 Internal Server Error', StringIO.new(xml))
    end

    e = assert_raise RCRest::CommunicationError do @fs.do_get end

    expected = <<-EOF.strip
Communication error: 500 Internal Server Error(OpenURI::HTTPError)

unhandled error:
<other_error>you did the bad thing</other_error>
    EOF

    assert_equal expected, e.message
  end

  def test_do_get_eof_error
    URI::HTTP.responses << proc do
      xml = '<error>you did the bad thing</error>'
      raise EOFError, 'end of file reached'
    end

    assert_raise RCRest::CommunicationError do @fs.do_get end
  end

  def test_do_post
    xml = '<result>stuff</result>'
    Net::HTTP.responses << xml

    result = @fs.do_post

    assert_equal xml, result.to_s

    assert_equal 1, Net::HTTP.params.length
    assert_equal 1, Net::HTTP.paths.length
    assert_empty Net::HTTP.responses

    assert_equal 'param=value', Net::HTTP.params.first
    assert_equal '/method', Net::HTTP.paths.first
  end

  def test_do_post_multipart
    xml = '<result>stuff</result>'
    Net::HTTP.responses << xml

    result = @fs.do_post_multipart

    assert_equal xml, result.to_s

    assert_equal 1, Net::HTTP.params.length
    assert_equal 1, Net::HTTP.paths.length
    assert_empty Net::HTTP.responses

    expected = <<-EOF.strip
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="param"\r
\r
value\r
--ac_2f_75_c0_43_fb_c3_67--
    EOF

    assert_equal expected, Net::HTTP.params.first
    assert_equal '/method', Net::HTTP.paths.first
  end

end

class TestRCRest < Test::Unit::TestCase

  def test_initialize
    e = assert_raise NotImplementedError do
      RCRest.new
    end

    assert_equal 'need to implement #intialize and set @url', e.message
  end

  def test_check_error
    r = RCRest.allocate
    assert_raise NotImplementedError do r.check_error nil end
  end

  def test_make_multipart
    srand 0

    r = RCRest.allocate
    boundary, data = r.make_multipart :a => 'b c', :x => 'y z',
                                      :array => ['v2', 'v1'],
                                      :newlines => "a\nb"

    assert_equal 'ac_2f_75_c0_43_fb_c3_67', boundary

    expected = <<-EOF.strip
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="a"\r
\r
b c\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="array"\r
\r
v1\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="array"\r
\r
v2\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="newlines"\r
\r
a
b\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="x"\r
\r
y z\r
--ac_2f_75_c0_43_fb_c3_67--
    EOF

    assert_equal expected, data
  end

  def test_make_url
    r = RCRest.allocate
    r.instance_variable_set :@url, URI.parse('http://example.com/')

    url = r.make_url :method, :a => 'b c', :x => 'y z', :array => ['v2', 'v1'],
                              :newlines => "a\nb", :funky => 'a;b+c&d'

    assert_equal 'http://example.com/method?a=b%20c&array=v1&array=v2&funky=a%3Bb%2Bc%26d&newlines=a%0Ab&x=y%20z',
                 url.to_s
  end

  def test_parse_response
    r = RCRest.allocate
    assert_raise NotImplementedError do r.parse_response nil end
  end

end

