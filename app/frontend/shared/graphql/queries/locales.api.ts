import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LocalesDocument = gql`
    query locales {
  locales {
    locale
    alias
    name
    dir
    active
  }
}
    `;
export function useLocalesQuery(options: VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.LocalesQuery, Types.LocalesQueryVariables>(LocalesDocument, {}, options);
}
export function useLocalesLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.LocalesQuery, Types.LocalesQueryVariables>(LocalesDocument, {}, options);
}
export type LocalesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.LocalesQuery, Types.LocalesQueryVariables>;