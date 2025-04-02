import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSignature.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSignatureQuery(defaults: Mocks.MockDefaultsValue<Types.TicketSignatureQuery, Types.TicketSignatureQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSignatureDocument, defaults)
}

export function waitForTicketSignatureQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSignatureQuery>(Operations.TicketSignatureDocument)
}

export function mockTicketSignatureQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSignatureDocument, message, extensions);
}
