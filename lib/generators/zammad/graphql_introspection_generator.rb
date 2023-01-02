# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::GraphqlIntrospectionGenerator < Rails::Generators::Base

  desc 'Create JSON from the GraphQL introspection information and output it to STDOUT'

  def generate
    result = Gql::ZammadSchema.execute(GraphQL::Introspection::INTROSPECTION_QUERY, variables: {}, context: { is_graphql_introspection_generator: true })
    raise "GraphQL schema could not be successfully generated: #{result['errors'].first['message']}" if result['errors']

    # rubocop:disable Rails/Output
    puts JSON.pretty_generate(result)
    # rubocop:enable Rails/Output
  end
end
