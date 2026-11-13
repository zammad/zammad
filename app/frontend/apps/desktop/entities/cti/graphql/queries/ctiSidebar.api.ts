import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiSidebarAttributesFragmentDoc } from '../fragments/ctiSidebarAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const CtiSidebarDocument = gql`
    query ctiSidebar {
  ctiSidebar {
    ...ctiSidebarAttributes
  }
}
    ${CtiSidebarAttributesFragmentDoc}`;
export function useCtiSidebarQuery(options: VueApolloComposable.useQuery.Options<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>(CtiSidebarDocument, options);
}
export function useCtiSidebarLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>(CtiSidebarDocument, options);
}
export type CtiSidebarQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.CtiSidebarQuery, Types.CtiSidebarQueryVariables>;