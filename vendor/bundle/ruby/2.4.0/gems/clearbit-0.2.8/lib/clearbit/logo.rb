module Clearbit
  class Logo
    ENDPOINT = 'https://logo.clearbit.com'

    def self.url(values)
      params = values.delete(params) || {}

      if size = values.delete(:size)
        params.merge!(size: size)
      end

      if format = values.delete(:format)
        params.merge!(format: format)
      end

      if greyscale = values.delete(:greyscale)
        params.merge!(greyscale: greyscale)
      end

      encoded_params = URI.encode_www_form(params)

      if domain = values.delete(:domain)
        raise ArgumentError, 'Invalid domain' unless domain =~ /^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$/
        if encoded_params.empty?
          "#{ENDPOINT}/#{domain}"
        else
          "#{ENDPOINT}/#{domain}?#{encoded_params}"
        end
      else
        raise ArgumentError, 'Invalid values'
      end
    end

    class << self
      alias_method :[], :url
    end
  end
end
