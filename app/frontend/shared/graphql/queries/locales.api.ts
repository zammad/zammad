import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LocalesDocument = gql`
    query locales($onlyActive: Boolean = false) {
  locales(onlyActive: $onlyActive) {
    locale
    alias
    name
    dir
    active
  }
}
    `;
export function useLocalesQuery(variables: Types.LocalesQueryVariables | VueCompositionApi.Ref<Types.LocalesQueryVariables> | ReactiveFunction<Types.LocalesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.LocalesQuery, Types.LocalesQueryVariables>(LocalesDocument, variables, options);
}
export function useLocalesLazyQuery(variables: Types.LocalesQueryVariables | VueCompositionApi.Ref<Types.LocalesQueryVariables> | ReactiveFunction<Types.LocalesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.LocalesQuery, Types.LocalesQueryVariables>(LocalesDocument, variables, options);
}
export type LocalesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.LocalesQuery, Types.LocalesQueryVariables>;