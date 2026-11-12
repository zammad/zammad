import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AiAssistanceTextToolsListDocument = gql`
    query aiAssistanceTextToolsList($groupId: ID, $ticketId: ID, $limit: Int) {
  aiAssistanceTextToolsList(groupId: $groupId, ticketId: $ticketId, limit: $limit) {
    id
    name
    active
  }
}
    `;
export function useAiAssistanceTextToolsListQuery(options: VueApolloComposable.useQuery.Options<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>(AiAssistanceTextToolsListDocument, options);
}
export function useAiAssistanceTextToolsListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>(AiAssistanceTextToolsListDocument, options);
}
export type AiAssistanceTextToolsListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>;