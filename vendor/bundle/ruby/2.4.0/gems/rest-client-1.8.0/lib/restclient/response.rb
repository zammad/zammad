module RestClient

  # A Response from RestClient, you can access the response body, the code or the headers.
  #
  module Response

    include AbstractResponse

    def body
      self
    end

    def self.create body, net_http_res, args, request
      result = body || ''
      result.extend Response
      result.response_set_vars(net_http_res, args, request)
      result
    end

  end
end
