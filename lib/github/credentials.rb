# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GitHub
  class Credentials

    QUERY = <<-'GRAPHQL'.freeze
      query {
        viewer {
          login
        }
      }
    GRAPHQL

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def verify!
      response = client.perform(
        query: GitHub::Credentials::QUERY,
      )
      return if response.dig('data', 'viewer', 'login').present?

      raise 'Invalid GitHub GraphQL API token'
    end
  end
end
