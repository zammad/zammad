import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDeviceAttributesFragmentDoc } from '../fragments/userDeviceAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentDevicesUpdatesDocument = gql`
    subscription userCurrentDevicesUpdates($userId: ID!) {
  userCurrentDevicesUpdates(userId: $userId) {
    devices {
      ...userDeviceAttributes
    }
  }
}
    ${UserDeviceAttributesFragmentDoc}`;
export function useUserCurrentDevicesUpdatesSubscription(variables: Types.UserCurrentDevicesUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.UserCurrentDevicesUpdatesSubscriptionVariables> | ReactiveFunction<Types.UserCurrentDevicesUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables>(UserCurrentDevicesUpdatesDocument, variables, options);
}
export type UserCurrentDevicesUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables>;