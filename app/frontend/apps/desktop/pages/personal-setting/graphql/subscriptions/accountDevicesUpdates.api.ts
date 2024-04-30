import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDeviceAttributesFragmentDoc } from '../fragments/userDeviceAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountDevicesUpdatesDocument = gql`
    subscription accountDevicesUpdates($userId: ID!) {
  accountDevicesUpdates(userId: $userId) {
    devices {
      ...userDeviceAttributes
    }
  }
}
    ${UserDeviceAttributesFragmentDoc}`;
export function useAccountDevicesUpdatesSubscription(variables: Types.AccountDevicesUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.AccountDevicesUpdatesSubscriptionVariables> | ReactiveFunction<Types.AccountDevicesUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.AccountDevicesUpdatesSubscription, Types.AccountDevicesUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.AccountDevicesUpdatesSubscription, Types.AccountDevicesUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.AccountDevicesUpdatesSubscription, Types.AccountDevicesUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.AccountDevicesUpdatesSubscription, Types.AccountDevicesUpdatesSubscriptionVariables>(AccountDevicesUpdatesDocument, variables, options);
}
export type AccountDevicesUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.AccountDevicesUpdatesSubscription, Types.AccountDevicesUpdatesSubscriptionVariables>;