import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { HistoryGroupFragmentDoc } from '../../../../../../shared/graphql/fragments/history.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OrganizationHistoryDocument = gql`
    query organizationHistory($organizationId: ID!) {
  organizationHistory(organizationId: $organizationId) {
    ...HistoryGroup
  }
}
    ${HistoryGroupFragmentDoc}`;
export function useOrganizationHistoryQuery(variables: Types.OrganizationHistoryQueryVariables | VueCompositionApi.Ref<Types.OrganizationHistoryQueryVariables> | ReactiveFunction<Types.OrganizationHistoryQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>(OrganizationHistoryDocument, variables, options);
}
export function useOrganizationHistoryLazyQuery(variables?: Types.OrganizationHistoryQueryVariables | VueCompositionApi.Ref<Types.OrganizationHistoryQueryVariables> | ReactiveFunction<Types.OrganizationHistoryQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>(OrganizationHistoryDocument, variables, options);
}
export type OrganizationHistoryQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>;