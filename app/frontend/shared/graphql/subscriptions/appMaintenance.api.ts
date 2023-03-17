import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AppMaintenanceDocument = gql`
    subscription appMaintenance {
  appMaintenance {
    type
  }
}
    `;
export function useAppMaintenanceSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables>(AppMaintenanceDocument, {}, options);
}
export type AppMaintenanceSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.AppMaintenanceSubscription, Types.AppMaintenanceSubscriptionVariables>;