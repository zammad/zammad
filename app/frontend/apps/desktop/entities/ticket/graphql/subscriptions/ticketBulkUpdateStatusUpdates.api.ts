import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentTicketBulkUpdateStatusUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables>(UserCurrentTicketBulkUpdateStatusUpdatesDocument, options);
}
export type UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription, Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscriptionVariables>;