import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useConfigUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables>(ConfigUpdatesDocument, options);
}
export type ConfigUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.ConfigUpdatesSubscription, Types.ConfigUpdatesSubscriptionVariables>;