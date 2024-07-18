import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketAttributesFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/ticketAttributes.api';
import { TicketMentionFragmentDoc } from '../../../../../../shared/entities/ticket/graphql/fragments/ticketMention.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketWithMentionLimitDocument = gql`
    query ticketWithMentionLimit($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String, $mentionsCount: Int = null) {
  ticket(
    ticket: {ticketId: $ticketId, ticketInternalId: $ticketInternalId, ticketNumber: $ticketNumber}
  ) {
    ...ticketAttributes
    createArticleType {
      id
      name
    }
    mentions(first: $mentionsCount) {
      totalCount
      edges {
        node {
          ...ticketMention
        }
        cursor
      }
    }
  }
}
    ${TicketAttributesFragmentDoc}
${TicketMentionFragmentDoc}`;
export function useTicketWithMentionLimitQuery(variables: Types.TicketWithMentionLimitQueryVariables | VueCompositionApi.Ref<Types.TicketWithMentionLimitQueryVariables> | ReactiveFunction<Types.TicketWithMentionLimitQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>(TicketWithMentionLimitDocument, variables, options);
}
export function useTicketWithMentionLimitLazyQuery(variables: Types.TicketWithMentionLimitQueryVariables | VueCompositionApi.Ref<Types.TicketWithMentionLimitQueryVariables> | ReactiveFunction<Types.TicketWithMentionLimitQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>(TicketWithMentionLimitDocument, variables, options);
}
export type TicketWithMentionLimitQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketWithMentionLimitQuery, Types.TicketWithMentionLimitQueryVariables>;