import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './add.api.ts'

export function mockFormUploadCacheAddMutation(defaults: Mocks.MockDefaultsValue<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.FormUploadCacheAddDocument, defaults)
}

export function waitForFormUploadCacheAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.FormUploadCacheAddMutation>(Operations.FormUploadCacheAddDocument)
}
