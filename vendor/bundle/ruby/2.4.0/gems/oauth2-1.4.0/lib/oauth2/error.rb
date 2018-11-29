module OAuth2
  class Error < StandardError
    attr_reader :response, :code, :description

    # standard error values include:
    # :invalid_request, :invalid_client, :invalid_token, :invalid_grant, :unsupported_grant_type, :invalid_scope
    def initialize(response)
      response.error = self
      @response = response

      if response.parsed.is_a?(Hash)
        @code = response.parsed['error']
        @description = response.parsed['error_description']
        error_description = "#{@code}: #{@description}"
      end

      super(error_message(response.body, :error_description => error_description))
    end

    # Makes a error message
    # @param [String] response_body response body of request
    # @param [String] opts :error_description error description to show first line
    def error_message(response_body, opts = {})
      message = []

      opts[:error_description] && message << opts[:error_description]

      error_message = if opts[:error_description] && opts[:error_description].respond_to?(:encoding)
                        script_encoding = opts[:error_description].encoding
                        response_body.encode(script_encoding, :invalid => :replace, :undef => :replace)
                      else
                        response_body
                      end

      message << error_message

      message.join("\n")
    end
  end
end
