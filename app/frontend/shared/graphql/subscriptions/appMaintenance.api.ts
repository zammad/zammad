import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AppMaintenanceDocument = gql`
    subscription appMaintenance {
  appMaintenance {
    type
  }
}
    `;
export function useAppMaintenanceSubscription(options: VueApolloComposable.useSubscription.Options<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables>(AppMaintenanceDocument, options);
}
export type AppMaintenanceSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables>;