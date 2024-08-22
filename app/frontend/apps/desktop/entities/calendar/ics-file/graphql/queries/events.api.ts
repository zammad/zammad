import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useCalendarIcsFileEventsQuery(variables: Types.CalendarIcsFileEventsQueryVariables | VueCompositionApi.Ref<Types.CalendarIcsFileEventsQueryVariables> | ReactiveFunction<Types.CalendarIcsFileEventsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>(CalendarIcsFileEventsDocument, variables, options);
}
export function useCalendarIcsFileEventsLazyQuery(variables?: Types.CalendarIcsFileEventsQueryVariables | VueCompositionApi.Ref<Types.CalendarIcsFileEventsQueryVariables> | ReactiveFunction<Types.CalendarIcsFileEventsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>(CalendarIcsFileEventsDocument, variables, options);
}
export type CalendarIcsFileEventsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CalendarIcsFileEventsQuery, Types.CalendarIcsFileEventsQueryVariables>;