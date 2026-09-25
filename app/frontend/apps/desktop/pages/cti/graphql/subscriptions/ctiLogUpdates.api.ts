import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiLogAttributesFragmentDoc } from '../fragments/ctiLogAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CtiLogUpdatesDocument = gql`
    subscription ctiLogUpdates {
  ctiLogUpdates {
    addLog {
      ...ctiLogAttributes
    }
    updateLog {
      ...ctiLogAttributes
    }
    removeLogId
  }
}
    ${CtiLogAttributesFragmentDoc}`;
export function useCtiLogUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables>(CtiLogUpdatesDocument, {}, options);
}
export type CtiLogUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables>;