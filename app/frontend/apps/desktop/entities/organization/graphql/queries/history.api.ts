import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { HistoryEventObjectFragmentDoc, HistoryEventFragmentDoc, HistoryIssuerFragmentDoc, HistoryGroupFragmentDoc } from '../../../../../../shared/graphql/fragments/history.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OrganizationHistoryDocument = gql`
    query organizationHistory($organizationId: ID!) {
  organizationHistory(organizationId: $organizationId) {
    ...HistoryGroup
  }
}
    ${HistoryGroupFragmentDoc}
${HistoryIssuerFragmentDoc}
${HistoryEventFragmentDoc}
${HistoryEventObjectFragmentDoc}`;
export function useOrganizationHistoryQuery(options: VueApolloComposable.useQuery.Options<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>) {
  return VueApolloComposable.useQuery<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>(OrganizationHistoryDocument, options);
}
export function useOrganizationHistoryLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>(OrganizationHistoryDocument, options);
}
export type OrganizationHistoryQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.OrganizationHistoryQuery, Types.OrganizationHistoryQueryVariables>;