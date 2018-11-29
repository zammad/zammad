module Autodiscover
  class PoxRequest
    include Autodiscover

    attr_reader :client, :options

    # @param client [Autodiscover::Client]
    # @param [Hash] **options
    # @option **options [Boolean] :ignore_ssl_errors Whether to keep trying if
    #   there are SSL errors
    def initialize(client, **options)
      @client = client
      @options = options
    end

    # @return [Autodiscover::PoxResponse, nil]
    def autodiscover
      available_urls.each do |url|
        response = client.http.post(url, request_body, {'Content-Type' => 'text/xml; charset=utf-8'})
        return PoxResponse.new(response.body) if good_response?(response)
      end
    end

    private

    def good_response?(response)
      response.status == 200
    end

    def available_urls(&block)
      return to_enum(__method__) unless block_given?
      formatted_https_urls.each {|url|
        logger.debug "Yielding HTTPS Url #{url}"
        handle_allowed_errors do
          yield url
        end
      }
      handle_allowed_errors do
        logger.debug "Yielding HTTP Redirected Url #{redirected_http_url}"
        yield redirected_http_url
      end
    end

    def formatted_https_urls
      @formatted_urls ||= %W{
        https://#{client.domain}/autodiscover/autodiscover.xml
        https://autodiscover.#{client.domain}/autodiscover/autodiscover.xml
      }
    end

    def redirected_http_url
      @redirected_http_url ||=
        begin
          response = client.http.get("http://autodiscover.#{client.domain}/autodiscover/autodiscover.xml")
          (response.status == 302) ? response.headers["Location"] : nil
        end
    end

    def request_body
      Nokogiri::XML::Builder.new do |xml| 
        xml.Autodiscover('xmlns' => 'http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006') {
          xml.Request {
            xml.EMailAddress client.email
            xml.AcceptableResponseSchema 'http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a'
          }
        }
      end.to_xml
    end

    def handle_allowed_errors
      yield
    rescue SocketError, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNREFUSED, HTTPClient::ConnectTimeoutError
    rescue OpenSSL::SSL::SSLError
      raise if !options[:ignore_ssl_errors]
    end
  end
end
