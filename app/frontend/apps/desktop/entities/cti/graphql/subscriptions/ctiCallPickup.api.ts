import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useCtiCallPickupSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables>(CtiCallPickupDocument, {}, options);
}
export type CtiCallPickupSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.CtiCallPickupSubscription, Types.CtiCallPickupSubscriptionVariables>;