import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './subscribe.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockMentionSubscribeMutation(defaults: Mocks.MockDefaultsValue<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.MentionSubscribeDocument, defaults)
}

export function waitForMentionSubscribeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.MentionSubscribeMutation>(Operations.MentionSubscribeDocument)
}

export function mockMentionSubscribeMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.MentionSubscribeDocument, message, extensions);
}
