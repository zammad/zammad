import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiSidebarAttributesFragmentDoc } from '../fragments/ctiSidebarAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CtiSidebarDocument = gql`
    query ctiSidebar {
  ctiSidebar {
    ...ctiSidebarAttributes
  }
}
    ${CtiSidebarAttributesFragmentDoc}`;
export function useCtiSidebarQuery(options: VueApolloComposable.UseQueryOptions<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>(CtiSidebarDocument, {}, options);
}
export function useCtiSidebarLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>(CtiSidebarDocument, {}, options);
}
export type CtiSidebarQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>;