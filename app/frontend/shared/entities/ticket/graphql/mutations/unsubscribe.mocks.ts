import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './unsubscribe.api.ts'

export function mockMentionUnsubscribeMutation(defaults: Mocks.MockDefaultsValue<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.MentionUnsubscribeDocument, defaults)
}

export function waitForMentionUnsubscribeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.MentionUnsubscribeMutation>(Operations.MentionUnsubscribeDocument)
}
