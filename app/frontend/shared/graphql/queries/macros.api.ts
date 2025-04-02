import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const MacrosDocument = gql`
    query macros($groupIds: [ID!]!) {
  macros(groupIds: $groupIds) {
    id
    active
    name
    uxFlowNextUp
  }
}
    `;
export function useMacrosQuery(variables: Types.MacrosQueryVariables | VueCompositionApi.Ref<Types.MacrosQueryVariables> | ReactiveFunction<Types.MacrosQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.MacrosQuery, Types.MacrosQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.MacrosQuery, Types.MacrosQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.MacrosQuery, Types.MacrosQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.MacrosQuery, Types.MacrosQueryVariables>(MacrosDocument, variables, options);
}
export function useMacrosLazyQuery(variables?: Types.MacrosQueryVariables | VueCompositionApi.Ref<Types.MacrosQueryVariables> | ReactiveFunction<Types.MacrosQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.MacrosQuery, Types.MacrosQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.MacrosQuery, Types.MacrosQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.MacrosQuery, Types.MacrosQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.MacrosQuery, Types.MacrosQueryVariables>(MacrosDocument, variables, options);
}
export type MacrosQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.MacrosQuery, Types.MacrosQueryVariables>;