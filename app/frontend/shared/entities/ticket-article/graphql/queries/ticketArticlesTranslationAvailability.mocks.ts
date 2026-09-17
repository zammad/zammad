import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticlesTranslationAvailability.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketArticlesTranslationAvailabilityQuery(defaults: Mocks.MockDefaultsValue<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticlesTranslationAvailabilityDocument, defaults)
}

export function waitForTicketArticlesTranslationAvailabilityQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticlesTranslationAvailabilityQuery>(Operations.TicketArticlesTranslationAvailabilityDocument)
}

export function mockTicketArticlesTranslationAvailabilityQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketArticlesTranslationAvailabilityDocument, message, extensions);
}
