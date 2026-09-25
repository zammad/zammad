import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CtiSidebarAttributesFragmentDoc } from '../fragments/ctiSidebarAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CtiSidebarUpdatesDocument = gql`
    subscription ctiSidebarUpdates {
  ctiSidebarUpdates {
    sidebar {
      ...ctiSidebarAttributes
    }
  }
}
    ${CtiSidebarAttributesFragmentDoc}`;
export function useCtiSidebarUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables>(CtiSidebarUpdatesDocument, {}, options);
}
export type CtiSidebarUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.CtiSidebarUpdatesSubscription, Types.CtiSidebarUpdatesSubscriptionVariables>;