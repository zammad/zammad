import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentContentTranslationExcludedLanguages.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentContentTranslationExcludedLanguagesMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentContentTranslationExcludedLanguagesMutation, Types.UserCurrentContentTranslationExcludedLanguagesMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentContentTranslationExcludedLanguagesDocument, defaults)
}

export function waitForUserCurrentContentTranslationExcludedLanguagesMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentContentTranslationExcludedLanguagesMutation>(Operations.UserCurrentContentTranslationExcludedLanguagesDocument)
}

export function mockUserCurrentContentTranslationExcludedLanguagesMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentContentTranslationExcludedLanguagesDocument, message, extensions);
}
