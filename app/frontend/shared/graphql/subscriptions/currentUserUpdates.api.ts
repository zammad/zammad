import * as Types from '../types';

import gql from 'graphql-tag';
import { CurrentUserAttributesFragmentDoc } from '../fragments/currentUserAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CurrentUserUpdatesDocument = gql`
    subscription currentUserUpdates($userId: ID!) {
  userUpdates(userId: $userId) {
    user {
      ...currentUserAttributes
    }
  }
}
    ${CurrentUserAttributesFragmentDoc}`;
export function useCurrentUserUpdatesSubscription(variables: Types.CurrentUserUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.CurrentUserUpdatesSubscriptionVariables> | ReactiveFunction<Types.CurrentUserUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables>(CurrentUserUpdatesDocument, variables, options);
}
export type CurrentUserUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.CurrentUserUpdatesSubscription, Types.CurrentUserUpdatesSubscriptionVariables>;