import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentContentTranslationTargetLocale.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentContentTranslationTargetLocaleMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentContentTranslationTargetLocaleMutation, Types.UserCurrentContentTranslationTargetLocaleMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentContentTranslationTargetLocaleDocument, defaults)
}

export function waitForUserCurrentContentTranslationTargetLocaleMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentContentTranslationTargetLocaleMutation>(Operations.UserCurrentContentTranslationTargetLocaleDocument)
}

export function mockUserCurrentContentTranslationTargetLocaleMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentContentTranslationTargetLocaleDocument, message, extensions);
}
