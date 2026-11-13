import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiSidebarAttributesFragmentDoc } from '../fragments/ctiSidebarAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const CtiSidebarUpdatesDocument = gql`
    subscription ctiSidebarUpdates {
  ctiSidebarUpdates {
    sidebar {
      ...ctiSidebarAttributes
    }
  }
}
    ${CtiSidebarAttributesFragmentDoc}`;
export function useCtiSidebarUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables>(CtiSidebarUpdatesDocument, options);
}
export type CtiSidebarUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables>;