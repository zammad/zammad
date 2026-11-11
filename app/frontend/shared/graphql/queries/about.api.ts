import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ProductAboutDocument = gql`
    query productAbout {
  productAbout
}
    `;
export function useProductAboutQuery(options: VueApolloComposable.useQuery.Options<Types.ProductAboutQuery, Types.ProductAboutQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>(ProductAboutDocument, options);
}
export function useProductAboutLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>(ProductAboutDocument, options);
}
export type ProductAboutQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>;