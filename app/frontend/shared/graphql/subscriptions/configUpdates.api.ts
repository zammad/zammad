import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ConfigUpdatesDocument = gql`
    subscription configUpdates {
  configUpdates {
    setting {
      key
      value
    }
  }
}
    `;
export function useConfigUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables>(ConfigUpdatesDocument, {}, options);
}
export type ConfigUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables>;