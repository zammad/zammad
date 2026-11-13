import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentOverviewListDocument = gql`
    query userCurrentOverviewList($ignoreUserConditions: Boolean!) {
  userCurrentTicketOverviews(ignoreUserConditions: $ignoreUserConditions) {
    id
    name
    organizationShared
    outOfOffice
  }
}
    `;
export function useUserCurrentOverviewListQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>(UserCurrentOverviewListDocument, options);
}
export function useUserCurrentOverviewListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>(UserCurrentOverviewListDocument, options);
}
export type UserCurrentOverviewListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>;