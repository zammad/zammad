import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const CtiCallPickupDocument = gql`
    subscription ctiCallPickup {
  ctiCallPickup {
    target {
      view
      customer {
        id
        internalId
      }
      log {
        id
        from
        fromPretty
      }
    }
  }
}
    `;
export function useCtiCallPickupSubscription(options: VueApolloComposable.useSubscription.Options<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables>(CtiCallPickupDocument, options);
}
export type CtiCallPickupSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables>;