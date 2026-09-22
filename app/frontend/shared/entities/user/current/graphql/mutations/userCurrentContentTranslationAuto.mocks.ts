import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentContentTranslationAuto.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentContentTranslationAutoMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentContentTranslationAutoMutation, Types.UserCurrentContentTranslationAutoMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentContentTranslationAutoDocument, defaults)
}

export function waitForUserCurrentContentTranslationAutoMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentContentTranslationAutoMutation>(Operations.UserCurrentContentTranslationAutoDocument)
}

export function mockUserCurrentContentTranslationAutoMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentContentTranslationAutoDocument, message, extensions);
}
