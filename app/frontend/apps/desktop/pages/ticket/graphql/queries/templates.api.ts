import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TemplatesDocument = gql`
    query templates($onlyActive: Boolean = false) {
  templates(onlyActive: $onlyActive) {
    id
    name
  }
}
    `;
export function useTemplatesQuery(variables: Types.TemplatesQueryVariables | VueCompositionApi.Ref<Types.TemplatesQueryVariables> | ReactiveFunction<Types.TemplatesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TemplatesQuery, Types.TemplatesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TemplatesQuery, Types.TemplatesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TemplatesQuery, Types.TemplatesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TemplatesQuery, Types.TemplatesQueryVariables>(TemplatesDocument, variables, options);
}
export function useTemplatesLazyQuery(variables: Types.TemplatesQueryVariables | VueCompositionApi.Ref<Types.TemplatesQueryVariables> | ReactiveFunction<Types.TemplatesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TemplatesQuery, Types.TemplatesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TemplatesQuery, Types.TemplatesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TemplatesQuery, Types.TemplatesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TemplatesQuery, Types.TemplatesQueryVariables>(TemplatesDocument, variables, options);
}
export type TemplatesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TemplatesQuery, Types.TemplatesQueryVariables>;