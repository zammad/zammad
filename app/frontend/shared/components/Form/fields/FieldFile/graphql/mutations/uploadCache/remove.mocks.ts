import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './remove.api.ts'

export function mockFormUploadCacheRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.FormUploadCacheRemoveDocument, defaults)
}

export function waitForFormUploadCacheRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.FormUploadCacheRemoveMutation>(Operations.FormUploadCacheRemoveDocument)
}
