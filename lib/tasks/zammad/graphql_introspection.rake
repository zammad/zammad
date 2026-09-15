# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do
  namespace :graphql do
    desc 'Output the GraphQL introspection information as JSON'
    task introspection: :environment do
      raise 'GraphQL schema generation is disabled for security reasons. To enable it in your system, set the following ENV ZAMMAD_GRAPHQL_INTROSPECTION=true' if !Gql::ZammadSchema.introspection_enabled?

      result = Gql::ZammadSchema.execute(GraphQL::Introspection::INTROSPECTION_QUERY, variables: {}, context: { is_graphql_introspection_generator: true })
      raise "GraphQL schema could not be successfully generated: #{result['errors'].first['message']}" if result['errors']

      puts JSON.pretty_generate(result)
    end
  end
end
