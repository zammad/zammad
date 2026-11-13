import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiLogAttributesFragmentDoc } from '../fragments/ctiLogAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const CtiLogsDocument = gql`
    query ctiLogs($cursor: String, $pageSize: Int = 25) {
  ctiLogs(after: $cursor, first: $pageSize) {
    totalCount
    edges {
      node {
        ...ctiLogAttributes
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    ${CtiLogAttributesFragmentDoc}`;
export function useCtiLogsQuery(options: VueApolloComposable.useQuery.Options<Types.CtiLogsQuery, Types.CtiLogsQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>(CtiLogsDocument, options);
}
export function useCtiLogsLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>(CtiLogsDocument, options);
}
export type CtiLogsQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.CtiLogsQuery, Types.CtiLogsQueryVariables>;