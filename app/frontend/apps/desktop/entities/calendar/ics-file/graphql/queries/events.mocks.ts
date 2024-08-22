import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './events.api.ts'

export function mockCalendarIcsFileEventsQuery(defaults: Mocks.MockDefaultsValue<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CalendarIcsFileEventsDocument, defaults)
}

export function waitForCalendarIcsFileEventsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CalendarIcsFileEventsQuery>(Operations.CalendarIcsFileEventsDocument)
}
