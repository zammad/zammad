import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const LocalesDocument = gql`
    query locales($onlyActive: Boolean = false) {
  locales(onlyActive: $onlyActive) {
    locale
    alias
    name
    dir
    active
    language
  }
}
    `;
export function useLocalesQuery(options: VueApolloComposable.useQuery.Options<Types.LocalesQuery, Types.LocalesQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.LocalesQuery, Types.LocalesQueryVariables>(LocalesDocument, options);
}
export function useLocalesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.LocalesQuery, Types.LocalesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.LocalesQuery, Types.LocalesQueryVariables>(LocalesDocument, options);
}
export type LocalesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.LocalesQuery, Types.LocalesQueryVariables>;