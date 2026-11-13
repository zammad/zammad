import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { HistoryEventObjectFragmentDoc, HistoryEventFragmentDoc, HistoryIssuerFragmentDoc, HistoryGroupFragmentDoc } from '../../../../../../shared/graphql/fragments/history.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserHistoryDocument = gql`
    query userHistory($userId: ID!) {
  userHistory(userId: $userId) {
    ...HistoryGroup
  }
}
    ${HistoryGroupFragmentDoc}
${HistoryIssuerFragmentDoc}
${HistoryEventFragmentDoc}
${HistoryEventObjectFragmentDoc}`;
export function useUserHistoryQuery(options: VueApolloComposable.useQuery.Options<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>(UserHistoryDocument, options);
}
export function useUserHistoryLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>(UserHistoryDocument, options);
}
export type UserHistoryQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>;