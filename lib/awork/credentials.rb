class Awork
  class Credentials

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def verify
      response = client.perform('get', 'clientapplications')
      return if response.dig('data', 0, 'clientId').present?

      raise __('Invalid Awork API token')
    end
  end
end