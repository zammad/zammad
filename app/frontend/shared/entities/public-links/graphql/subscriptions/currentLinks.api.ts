import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { PublicLinkAttributesFragmentDoc } from '../../../../graphql/fragments/publicLinkAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const PublicLinkUpdatesDocument = gql`
    subscription publicLinkUpdates($screen: EnumPublicLinksScreen!) {
  publicLinkUpdates(screen: $screen) {
    publicLinks {
      ...publicLinkAttributes
    }
  }
}
    ${PublicLinkAttributesFragmentDoc}`;
export function usePublicLinkUpdatesSubscription(variables: Types.PublicLinkUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.PublicLinkUpdatesSubscriptionVariables> | ReactiveFunction<Types.PublicLinkUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables>(PublicLinkUpdatesDocument, variables, options);
}
export type PublicLinkUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables>;