import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './translations.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTranslationsQuery(defaults: Mocks.MockDefaultsValue<Types.TranslationsQuery, Types.TranslationsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TranslationsDocument, defaults)
}

export function waitForTranslationsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TranslationsQuery>(Operations.TranslationsDocument)
}

export function mockTranslationsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TranslationsDocument, message, extensions);
}
