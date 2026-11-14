import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { PublicLinkAttributesFragmentDoc } from '../../../../graphql/fragments/publicLinkAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const PublicLinkUpdatesDocument = gql`
    subscription publicLinkUpdates($screen: EnumPublicLinksScreen!) {
  publicLinkUpdates(screen: $screen) {
    publicLinks {
      ...publicLinkAttributes
    }
  }
}
    ${PublicLinkAttributesFragmentDoc}`;
export function usePublicLinkUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables>(PublicLinkUpdatesDocument, options);
}
export type PublicLinkUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.PublicLinkUpdatesSubscription, Types.PublicLinkUpdatesSubscriptionVariables>;