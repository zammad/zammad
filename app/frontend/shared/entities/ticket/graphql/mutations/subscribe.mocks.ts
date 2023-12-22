import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './subscribe.api.ts'

export function mockMentionSubscribeMutation(defaults: Mocks.MockDefaultsValue<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.MentionSubscribeDocument, defaults)
}

export function waitForMentionSubscribeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.MentionSubscribeMutation>(Operations.MentionSubscribeDocument)
}
