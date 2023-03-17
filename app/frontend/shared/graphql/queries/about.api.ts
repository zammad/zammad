import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ProductAboutDocument = gql`
    query productAbout {
  productAbout
}
    `;
export function useProductAboutQuery(options: VueApolloComposable.UseQueryOptions<Types.ProductAboutQuery, Types.ProductAboutQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>(ProductAboutDocument, {}, options);
}
export function useProductAboutLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.ProductAboutQuery, Types.ProductAboutQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>(ProductAboutDocument, {}, options);
}
export type ProductAboutQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>;