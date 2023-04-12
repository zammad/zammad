class Awork
  class Credentials

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def verify
      # request the clientapplications just to see if the authorization works
      response = client.perform('get', 'clientapplications')
      return if response[0].dig('clientId').present?

      raise __('Invalid Awork API token')
    end
  end
end