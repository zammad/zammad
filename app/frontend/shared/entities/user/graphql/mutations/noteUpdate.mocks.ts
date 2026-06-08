import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './noteUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserNoteUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.UserNoteUpdateMutation, Types.UserNoteUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserNoteUpdateDocument, defaults)
}

export function waitForUserNoteUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserNoteUpdateMutation>(Operations.UserNoteUpdateDocument)
}

export function mockUserNoteUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserNoteUpdateDocument, message, extensions);
}
