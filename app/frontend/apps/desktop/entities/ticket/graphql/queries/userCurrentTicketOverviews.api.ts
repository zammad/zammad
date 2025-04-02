import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OverviewAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/overviewAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTicketOverviewsDocument = gql`
    query userCurrentTicketOverviews($ignoreUserConditions: Boolean!, $withTicketCount: Boolean!) {
  userCurrentTicketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    ...overviewAttributes
    viewColumnsRaw
  }
}
    ${OverviewAttributesFragmentDoc}`;
export function useUserCurrentTicketOverviewsQuery(variables: Types.UserCurrentTicketOverviewsQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTicketOverviewsQueryVariables> | ReactiveFunction<Types.UserCurrentTicketOverviewsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>(UserCurrentTicketOverviewsDocument, variables, options);
}
export function useUserCurrentTicketOverviewsLazyQuery(variables?: Types.UserCurrentTicketOverviewsQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTicketOverviewsQueryVariables> | ReactiveFunction<Types.UserCurrentTicketOverviewsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>(UserCurrentTicketOverviewsDocument, variables, options);
}
export type UserCurrentTicketOverviewsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>;