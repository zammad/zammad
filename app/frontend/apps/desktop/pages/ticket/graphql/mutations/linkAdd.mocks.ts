import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './linkAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockLinkAddMutation(defaults: Mocks.MockDefaultsValue<Types.LinkAddMutation, Types.LinkAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.LinkAddDocument, defaults)
}

export function waitForLinkAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.LinkAddMutation>(Operations.LinkAddDocument)
}

export function mockLinkAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.LinkAddDocument, message, extensions);
}
