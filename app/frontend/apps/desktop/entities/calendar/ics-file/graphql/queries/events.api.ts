import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const CalendarIcsFileEventsDocument = gql`
    query calendarIcsFileEvents($fileId: ID!) {
  calendarIcsFileEvents(fileId: $fileId) {
    title
    location
    startDate
    endDate
    organizer
    attendees
    description
  }
}
    `;
export function useCalendarIcsFileEventsQuery(options: VueApolloComposable.useQuery.Options<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>(CalendarIcsFileEventsDocument, options);
}
export function useCalendarIcsFileEventsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>(CalendarIcsFileEventsDocument, options);
}
export type CalendarIcsFileEventsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>;