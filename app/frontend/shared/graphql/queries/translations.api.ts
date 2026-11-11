import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TranslationsDocument = gql`
    query translations($locale: String!, $cacheKey: String) {
  translations(locale: $locale, cacheKey: $cacheKey) {
    isCacheStillValid
    cacheKey
    translations
  }
}
    `;
export function useTranslationsQuery(options: VueApolloComposable.useQuery.Options<Types.TranslationsQuery, Types.TranslationsQueryVariables>) {
  return VueApolloComposable.useQuery<Types.TranslationsQuery, Types.TranslationsQueryVariables>(TranslationsDocument, options);
}
export function useTranslationsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TranslationsQuery, Types.TranslationsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TranslationsQuery, Types.TranslationsQueryVariables>(TranslationsDocument, options);
}
export type TranslationsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TranslationsQuery, Types.TranslationsQueryVariables>;