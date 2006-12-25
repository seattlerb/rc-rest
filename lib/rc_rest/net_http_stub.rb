require 'net/http'

class Net::HTTPResponse

  ##
  # Setter for body content

  attr_accessor :body

end

class Net::HTTP

  @params = nil
  @paths = nil
  @responses = nil

  class << self

    ##
    # Records submitted POST params

    attr_accessor :params

    ##
    # Records POST paths

    attr_accessor :paths

    ##
    # Holds POST body responses

    attr_accessor :responses

    remove_method :start

  end

  ##
  # Override Net::HTTP::start to not connect

  def self.start(host, port)
    yield Net::HTTP.new(host)
  end

  remove_method :request

  ##
  # Override Net::HTTP#request to fake its results

  def request(req)
    self.class.paths << req.path
    self.class.params << req.body
    res = Net::HTTPResponse.new '1.0', 200, 'OK'
    res.body = self.class.responses.shift
    res
  end

end

