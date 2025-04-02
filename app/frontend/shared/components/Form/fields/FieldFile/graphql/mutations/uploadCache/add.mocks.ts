import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './add.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockFormUploadCacheAddMutation(defaults: Mocks.MockDefaultsValue<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.FormUploadCacheAddDocument, defaults)
}

export function waitForFormUploadCacheAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.FormUploadCacheAddMutation>(Operations.FormUploadCacheAddDocument)
}

export function mockFormUploadCacheAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.FormUploadCacheAddDocument, message, extensions);
}
