import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTicketOverviewsDocument = gql`
    query userCurrentTicketOverviews($ignoreUserConditions: Boolean!, $withTicketCount: Boolean!) {
  userCurrentTicketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    ...overviewAttributes
    viewColumnsRaw
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useUserCurrentTicketOverviewsQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>(UserCurrentTicketOverviewsDocument, options);
}
export function useUserCurrentTicketOverviewsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>(UserCurrentTicketOverviewsDocument, options);
}
export type UserCurrentTicketOverviewsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>;