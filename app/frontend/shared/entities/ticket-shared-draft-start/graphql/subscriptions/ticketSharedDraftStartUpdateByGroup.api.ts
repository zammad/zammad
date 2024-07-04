import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketSharedDraftStartUpdateByGroupDocument = gql`
    subscription ticketSharedDraftStartUpdateByGroup($groupId: ID!) {
  ticketSharedDraftStartUpdateByGroup(groupId: $groupId) {
    sharedDraftStarts {
      ...ticketSharedDraftStartAttributes
    }
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}`;
export function useTicketSharedDraftStartUpdateByGroupSubscription(variables: Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables | VueCompositionApi.Ref<Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables> | ReactiveFunction<Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>(TicketSharedDraftStartUpdateByGroupDocument, variables, options);
}
export type TicketSharedDraftStartUpdateByGroupSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>;