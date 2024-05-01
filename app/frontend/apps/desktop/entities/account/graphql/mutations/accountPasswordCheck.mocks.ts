import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountPasswordCheck.api.ts'

export function mockAccountPasswordCheckMutation(defaults: Mocks.MockDefaultsValue<Types.AccountPasswordCheckMutation, Types.AccountPasswordCheckMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountPasswordCheckDocument, defaults)
}

export function waitForAccountPasswordCheckMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountPasswordCheckMutation>(Operations.AccountPasswordCheckDocument)
}
