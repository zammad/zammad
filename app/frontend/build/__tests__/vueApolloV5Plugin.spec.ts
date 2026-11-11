// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'

// The plugin resolves the CJS build of graphql; building the schema from the
// ESM import would fail its cross-realm instanceOf checks.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { buildSchema, parse } = require('graphql')

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { plugin } = require('../vueApolloV5Plugin.js')

const schema = buildSchema(`
  type Query {
    user(userId: ID!): User
    users: [User!]!
  }

  type Mutation {
    userUpdate(userId: ID!, name: String): User
  }

  type Subscription {
    userUpdated(userId: ID!): User
  }

  type User {
    id: ID!
    name: String
  }
`)

interface PluginOutput {
  prepend: string[]
  content: string
}

const generate = (sdl: string, config: Record<string, unknown> = {}): string => {
  const result: PluginOutput = plugin(
    schema,
    [{ location: 'test.graphql', document: parse(sdl) }],
    {
      // Mirrors the repository codegen config.
      importOperationTypesFrom: 'Types',
      addDocBlocks: false,
      ...config,
    },
  )

  return [...result.prepend, result.content].join('\n')
}

describe('vueApolloV5Plugin', () => {
  it('requires the options for a query with a non-nullable variable and emits the lazy composable with optional options', () => {
    expect(generate('query user($userId: ID!) { user(userId: $userId) { id name } }'))
      .toMatchInlineSnapshot(`
        "import gql from 'graphql-tag';
        import * as VueApolloComposable from '@vue/apollo-composable';

        export const UserDocument = gql\`
            query user($userId: ID!) {
          user(userId: $userId) {
            id
            name
          }
        }
            \`;
        export function useUserQuery(options: VueApolloComposable.useQuery.Options<Types.UserQuery, Types.UserQueryVariables>) {
          return VueApolloComposable.useQuery<Types.UserQuery, Types.UserQueryVariables>(UserDocument, options);
        }
        export function useUserLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserQuery, Types.UserQueryVariables>) {
          return VueApolloComposable.useLazyQuery<Types.UserQuery, Types.UserQueryVariables>(UserDocument, options);
        }
        export type UserQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserQuery, Types.UserQueryVariables>;"
      `)
  })

  it('defaults the options to an empty object for a query without variables', () => {
    expect(generate('query users { users { id name } }')).toMatchInlineSnapshot(`
      "import gql from 'graphql-tag';
      import * as VueApolloComposable from '@vue/apollo-composable';

      export const UsersDocument = gql\`
          query users {
        users {
          id
          name
        }
      }
          \`;
      export function useUsersQuery(options: VueApolloComposable.useQuery.Options<Types.UsersQuery, Types.UsersQueryVariables> = {}) {
        return VueApolloComposable.useQuery<Types.UsersQuery, Types.UsersQueryVariables>(UsersDocument, options);
      }
      export function useUsersLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UsersQuery, Types.UsersQueryVariables>) {
        return VueApolloComposable.useLazyQuery<Types.UsersQuery, Types.UsersQueryVariables>(UsersDocument, options);
      }
      export type UsersQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UsersQuery, Types.UsersQueryVariables>;"
    `)
  })

  it('defaults the options to an empty object for a mutation despite its non-nullable variable', () => {
    expect(
      generate(
        'mutation userUpdate($userId: ID!, $name: String) { userUpdate(userId: $userId, name: $name) { id } }',
      ),
    ).toMatchInlineSnapshot(`
      "import gql from 'graphql-tag';
      import * as VueApolloComposable from '@vue/apollo-composable';

      export const UserUpdateDocument = gql\`
          mutation userUpdate($userId: ID!, $name: String) {
        userUpdate(userId: $userId, name: $name) {
          id
        }
      }
          \`;
      export function useUserUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.UserUpdateMutation, Types.UserUpdateMutationVariables> = {}) {
        return VueApolloComposable.useMutation<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>(UserUpdateDocument, options);
      }
      export type UserUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>;"
    `)
  })

  it('requires the options for a subscription with a non-nullable variable', () => {
    expect(
      generate(
        'subscription userUpdated($userId: ID!) { userUpdated(userId: $userId) { id name } }',
      ),
    ).toMatchInlineSnapshot(`
      "import gql from 'graphql-tag';
      import * as VueApolloComposable from '@vue/apollo-composable';

      export const UserUpdatedDocument = gql\`
          subscription userUpdated($userId: ID!) {
        userUpdated(userId: $userId) {
          id
          name
        }
      }
          \`;
      export function useUserUpdatedSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserUpdatedSubscription, Types.UserUpdatedSubscriptionVariables>) {
        return VueApolloComposable.useSubscription<Types.UserUpdatedSubscription, Types.UserUpdatedSubscriptionVariables>(UserUpdatedDocument, options);
      }
      export type UserUpdatedSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserUpdatedSubscription, Types.UserUpdatedSubscriptionVariables>;"
    `)
  })

  it('merges a configured clientId into the options at call time', () => {
    expect(generate('query users { users { id } }', { clientId: 'customClient' }))
      .toMatchInlineSnapshot(`
      "import gql from 'graphql-tag';
      import * as VueApolloComposable from '@vue/apollo-composable';

      export const UsersDocument = gql\`
          query users {
        users {
          id
        }
      }
          \`;
      export function useUsersQuery(options: VueApolloComposable.useQuery.Options<Types.UsersQuery, Types.UsersQueryVariables> = {}) {
        return VueApolloComposable.useQuery<Types.UsersQuery, Types.UsersQueryVariables>(UsersDocument, { clientId: 'customClient', ...options });
      }
      export function useUsersLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UsersQuery, Types.UsersQueryVariables>) {
        return VueApolloComposable.useLazyQuery<Types.UsersQuery, Types.UsersQueryVariables>(UsersDocument, { clientId: 'customClient', ...options });
      }
      export type UsersQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UsersQuery, Types.UsersQueryVariables>;"
    `)
  })

  it('emits a fragment-only document without composable import or ReactiveFunction', () => {
    const output = generate('fragment userAttributes on User { id name }')

    expect(output).not.toContain('@vue/apollo-composable')
    expect(output).not.toContain('ReactiveFunction')
    expect(output).toMatchInlineSnapshot(`
      "import gql from 'graphql-tag';
      export const UserAttributesFragmentDoc = gql\`
          fragment userAttributes on User {
        id
        name
      }
          \`;"
    `)
  })
})
