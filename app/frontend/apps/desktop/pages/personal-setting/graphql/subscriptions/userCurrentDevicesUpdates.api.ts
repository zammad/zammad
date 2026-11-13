import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDeviceAttributesFragmentDoc } from '../fragments/userDeviceAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentDevicesUpdatesDocument = gql`
    subscription userCurrentDevicesUpdates {
  userCurrentDevicesUpdates {
    devices {
      ...userDeviceAttributes
    }
  }
}
    ${UserDeviceAttributesFragmentDoc}`;
export function useUserCurrentDevicesUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables>(UserCurrentDevicesUpdatesDocument, options);
}
export type UserCurrentDevicesUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentDevicesUpdatesSubscription, Types.UserCurrentDevicesUpdatesSubscriptionVariables>;