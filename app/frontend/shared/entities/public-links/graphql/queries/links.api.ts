import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { PublicLinkAttributesFragmentDoc } from '../../../../graphql/fragments/publicLinkAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const PublicLinksDocument = gql`
    query publicLinks($screen: EnumPublicLinksScreen!) {
  publicLinks(screen: $screen) {
    ...publicLinkAttributes
  }
}
    ${PublicLinkAttributesFragmentDoc}`;
export function usePublicLinksQuery(options: VueApolloComposable.useQuery.Options<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>) {
  return VueApolloComposable.useQuery<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>(PublicLinksDocument, options);
}
export function usePublicLinksLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>(PublicLinksDocument, options);
}
export type PublicLinksQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>;