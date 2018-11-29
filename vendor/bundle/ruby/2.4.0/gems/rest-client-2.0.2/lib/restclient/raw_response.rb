module RestClient
  # The response from RestClient on a raw request looks like a string, but is
  # actually one of these.  99% of the time you're making a rest call all you
  # care about is the body, but on the occassion you want to fetch the
  # headers you can:
  #
  #   RestClient.get('http://example.com').headers[:content_type]
  #
  # In addition, if you do not use the response as a string, you can access
  # a Tempfile object at res.file, which contains the path to the raw
  # downloaded request body.
  class RawResponse

    include AbstractResponse

    attr_reader :file, :request

    def inspect
      "<RestClient::RawResponse @code=#{code.inspect}, @file=#{file.inspect}, @request=#{request.inspect}>"
    end

    def initialize(tempfile, net_http_res, request)
      @net_http_res = net_http_res
      @file = tempfile
      @request = request
    end

    def to_s
      @file.open
      @file.read
    end

    def size
      File.size file
    end

  end
end
