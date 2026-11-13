import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiLogAttributesFragmentDoc } from '../fragments/ctiLogAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useCtiLogUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables>(CtiLogUpdatesDocument, options);
}
export type CtiLogUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.CtiLogUpdatesSubscription, Types.CtiLogUpdatesSubscriptionVariables>;