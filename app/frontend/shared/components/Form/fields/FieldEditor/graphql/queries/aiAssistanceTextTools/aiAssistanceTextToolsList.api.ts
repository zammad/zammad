import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AiAssistanceTextToolsListDocument = gql`
    query aiAssistanceTextToolsList($groupId: ID, $ticketId: ID, $limit: Int) {
  aiAssistanceTextToolsList(groupId: $groupId, ticketId: $ticketId, limit: $limit) {
    id
    name
    active
  }
}
    `;
export function useAiAssistanceTextToolsListQuery(variables: Types.AiAssistanceTextToolsListQueryVariables | VueCompositionApi.Ref<Types.AiAssistanceTextToolsListQueryVariables> | ReactiveFunction<Types.AiAssistanceTextToolsListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>(AiAssistanceTextToolsListDocument, variables, options);
}
export function useAiAssistanceTextToolsListLazyQuery(variables: Types.AiAssistanceTextToolsListQueryVariables | VueCompositionApi.Ref<Types.AiAssistanceTextToolsListQueryVariables> | ReactiveFunction<Types.AiAssistanceTextToolsListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>(AiAssistanceTextToolsListDocument, variables, options);
}
export type AiAssistanceTextToolsListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AiAssistanceTextToolsListQuery, Types.AiAssistanceTextToolsListQueryVariables>;