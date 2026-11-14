import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketSharedDraftStartAttributesFragmentDoc } from '../fragments/ticketSharedDraftStartAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketSharedDraftStartUpdateByGroupDocument = gql`
    subscription ticketSharedDraftStartUpdateByGroup($groupId: ID!) {
  ticketSharedDraftStartUpdateByGroup(groupId: $groupId) {
    sharedDraftStarts {
      ...ticketSharedDraftStartAttributes
    }
  }
}
    ${TicketSharedDraftStartAttributesFragmentDoc}`;
export function useTicketSharedDraftStartUpdateByGroupSubscription(options: VueApolloComposable.useSubscription.Options<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>(TicketSharedDraftStartUpdateByGroupDocument, options);
}
export type TicketSharedDraftStartUpdateByGroupSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TicketSharedDraftStartUpdateByGroupSubscription, Types.TicketSharedDraftStartUpdateByGroupSubscriptionVariables>;