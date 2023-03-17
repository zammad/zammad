import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TranslationsDocument = gql`
    query translations($locale: String!, $cacheKey: String) {
  translations(locale: $locale, cacheKey: $cacheKey) {
    isCacheStillValid
    cacheKey
    translations
  }
}
    `;
export function useTranslationsQuery(variables: Types.TranslationsQueryVariables | VueCompositionApi.Ref<Types.TranslationsQueryVariables> | ReactiveFunction<Types.TranslationsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TranslationsQuery, Types.TranslationsQueryVariables>(TranslationsDocument, variables, options);
}
export function useTranslationsLazyQuery(variables: Types.TranslationsQueryVariables | VueCompositionApi.Ref<Types.TranslationsQueryVariables> | ReactiveFunction<Types.TranslationsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TranslationsQuery, Types.TranslationsQueryVariables>(TranslationsDocument, variables, options);
}
export type TranslationsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TranslationsQuery, Types.TranslationsQueryVariables>;