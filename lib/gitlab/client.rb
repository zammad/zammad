# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'graphql/client'

class GitLab
  class Client

    delegate_missing_to :client

    attr_reader :endpoint

    def initialize(endpoint, api_token, schema: nil)
      @endpoint  = endpoint
      @api_token = api_token
      schema(schema) if schema.present?
    end

    def schema(source = http_client)
      @schema ||= ::GraphQL::Client.load_schema(source)
    end

    private

    def http_client
      @http_client ||= GitLab::HttpClient.new(@endpoint, @api_token)
    end

    def client
      @client ||= begin
        GraphQL::Client.new(
          schema:  schema,
          execute: http_client,
        ).tap do |client|
          client.allow_dynamic_queries = true
        end
      end
    end
  end
end
