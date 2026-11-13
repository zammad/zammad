import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentRecentCloseListDocument = gql`
    query userCurrentRecentCloseList($limit: Int) {
  userCurrentRecentCloseList(limit: $limit) {
    __typename
    ... on Ticket {
      id
      internalId
      title
      number
      state {
        id
        name
      }
      priority {
        id
        name
        defaultCreate
        uiColor
      }
      stateColorCode
    }
    ... on User {
      id
      internalId
      fullname
      active
    }
    ... on Organization {
      id
      internalId
      name
      active
    }
  }
}
    `;
export function useUserCurrentRecentCloseListQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>(UserCurrentRecentCloseListDocument, options);
}
export function useUserCurrentRecentCloseListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>(UserCurrentRecentCloseListDocument, options);
}
export type UserCurrentRecentCloseListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>;