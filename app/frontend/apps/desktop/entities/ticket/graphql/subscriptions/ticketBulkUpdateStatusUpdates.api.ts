import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTicketBulkUpdateStatusUpdatesDocument = gql`
    subscription userCurrentTicketBulkUpdateStatusUpdates {
  userCurrentTicketBulkUpdateStatusUpdates {
    bulkUpdateStatus {
      status
      total
      processedCount
      failedCount
    }
  }
}
    `;
export function useUserCurrentTicketBulkUpdateStatusUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables>(UserCurrentTicketBulkUpdateStatusUpdatesDocument, {}, options);
}
export type UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables>;