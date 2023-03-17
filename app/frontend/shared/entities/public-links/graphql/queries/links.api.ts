import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { PublicLinkAttributesFragmentDoc } from '../../../../graphql/fragments/publicLinkAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const PublicLinksDocument = gql`
    query publicLinks($screen: EnumPublicLinksScreen!) {
  publicLinks(screen: $screen) {
    ...publicLinkAttributes
  }
}
    ${PublicLinkAttributesFragmentDoc}`;
export function usePublicLinksQuery(variables: Types.PublicLinksQueryVariables | VueCompositionApi.Ref<Types.PublicLinksQueryVariables> | ReactiveFunction<Types.PublicLinksQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.PublicLinksQuery, Types.PublicLinksQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>(PublicLinksDocument, variables, options);
}
export function usePublicLinksLazyQuery(variables: Types.PublicLinksQueryVariables | VueCompositionApi.Ref<Types.PublicLinksQueryVariables> | ReactiveFunction<Types.PublicLinksQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.PublicLinksQuery, Types.PublicLinksQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>(PublicLinksDocument, variables, options);
}
export type PublicLinksQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>;