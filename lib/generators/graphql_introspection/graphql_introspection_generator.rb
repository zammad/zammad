# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Generators::GraphqlIntrospection::GraphqlIntrospectionGenerator < Rails::Generators::Base

  def generate
    result = Gql::ZammadSchema.execute(introspection_query, variables: {}, context: { is_graphql_introspection_generator: true })
    raise 'GraphQL schema could not be successfully generated' if result['errors']

    # rubocop:disable Rails/Output
    puts JSON.pretty_generate(result)
    # rubocop:enable Rails/Output
  end

  private

  def introspection_query
    <<~INTROSPECTION_QUERY
      query IntrospectionQuery {
        __schema {
          queryType {
            name
          }
          mutationType {
            name
          }
          subscriptionType {
            name
          }
          types {
            ...FullType
          }
          directives {
            name
            description
            locations
            args {
              ...InputValue
            }
          }
        }
      }

      fragment FullType on __Type {
        kind
        name
        description
        fields(includeDeprecated: true) {
          name
          description
          args {
            ...InputValue
          }
          type {
            ...TypeRef
          }
          isDeprecated
          deprecationReason
        }
        inputFields {
          ...InputValue
        }
        interfaces {
          ...TypeRef
        }
        enumValues(includeDeprecated: true) {
          name
          description
          isDeprecated
          deprecationReason
        }
        possibleTypes {
          ...TypeRef
        }
      }

      fragment InputValue on __InputValue {
        name
        description
        type {
          ...TypeRef
        }
        defaultValue
      }

      fragment TypeRef on __Type {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                  ofType {
                    kind
                    name
                    ofType {
                      kind
                      name
                    }
                  }
                }
              }
            }
          }
        }
      }
    INTROSPECTION_QUERY
  end
end

# Allow Rails to find the generator
class GraphqlIntrospectionGenerator < Generators::GraphqlIntrospection::GraphqlIntrospectionGenerator
end
