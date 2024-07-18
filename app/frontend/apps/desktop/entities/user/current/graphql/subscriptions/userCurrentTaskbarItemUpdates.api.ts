import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemUpdatesDocument = gql`
    subscription userCurrentTaskbarItemUpdates($userId: ID!, $app: EnumTaskbarApp!) {
  userCurrentTaskbarItemUpdates(userId: $userId, app: $app) {
    addItem {
      ...userCurrentTaskbarItemAttributes
    }
    updateItem {
      ...userCurrentTaskbarItemAttributes
    }
    removeItem
  }
}
    ${UserCurrentTaskbarItemAttributesFragmentDoc}`;
export function useUserCurrentTaskbarItemUpdatesSubscription(variables: Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>(UserCurrentTaskbarItemUpdatesDocument, variables, options);
}
export type UserCurrentTaskbarItemUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>;