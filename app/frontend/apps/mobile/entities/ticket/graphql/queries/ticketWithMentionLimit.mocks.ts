import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketWithMentionLimit.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketWithMentionLimitQuery(defaults: Mocks.MockDefaultsValue<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketWithMentionLimitDocument, defaults)
}

export function waitForTicketWithMentionLimitQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketWithMentionLimitQuery>(Operations.TicketWithMentionLimitDocument)
}

export function mockTicketWithMentionLimitQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketWithMentionLimitDocument, message, extensions);
}
