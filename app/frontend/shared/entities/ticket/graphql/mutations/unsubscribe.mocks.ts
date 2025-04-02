import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './unsubscribe.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockMentionUnsubscribeMutation(defaults: Mocks.MockDefaultsValue<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.MentionUnsubscribeDocument, defaults)
}

export function waitForMentionUnsubscribeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.MentionUnsubscribeMutation>(Operations.MentionUnsubscribeDocument)
}

export function mockMentionUnsubscribeMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.MentionUnsubscribeDocument, message, extensions);
}
