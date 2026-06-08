import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { HistoryGroupFragmentDoc } from '../../../../../../shared/graphql/fragments/history.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserHistoryDocument = gql`
    query userHistory($userId: ID!) {
  userHistory(userId: $userId) {
    ...HistoryGroup
  }
}
    ${HistoryGroupFragmentDoc}`;
export function useUserHistoryQuery(variables: Types.UserHistoryQueryVariables | VueCompositionApi.Ref<Types.UserHistoryQueryVariables> | ReactiveFunction<Types.UserHistoryQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserHistoryQuery, Types.UserHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>(UserHistoryDocument, variables, options);
}
export function useUserHistoryLazyQuery(variables?: Types.UserHistoryQueryVariables | VueCompositionApi.Ref<Types.UserHistoryQueryVariables> | ReactiveFunction<Types.UserHistoryQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserHistoryQuery, Types.UserHistoryQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>(UserHistoryDocument, variables, options);
}
export type UserHistoryQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>;