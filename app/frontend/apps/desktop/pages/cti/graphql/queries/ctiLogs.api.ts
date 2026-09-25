import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiLogAttributesFragmentDoc } from '../fragments/ctiLogAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CtiLogsDocument = gql`
    query ctiLogs($cursor: String, $pageSize: Int = 25) {
  ctiLogs(after: $cursor, first: $pageSize) {
    totalCount
    edges {
      node {
        ...ctiLogAttributes
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    ${CtiLogAttributesFragmentDoc}`;
export function useCtiLogsQuery(variables: Types.CtiLogsQueryVariables | VueCompositionApi.Ref<Types.CtiLogsQueryVariables> | ReactiveFunction<Types.CtiLogsQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.CtiLogsQuery, Types.CtiLogsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>(CtiLogsDocument, variables, options);
}
export function useCtiLogsLazyQuery(variables: Types.CtiLogsQueryVariables | VueCompositionApi.Ref<Types.CtiLogsQueryVariables> | ReactiveFunction<Types.CtiLogsQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.CtiLogsQuery, Types.CtiLogsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>(CtiLogsDocument, variables, options);
}
export type CtiLogsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>;