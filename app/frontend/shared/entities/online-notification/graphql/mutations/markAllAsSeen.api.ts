import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OnlineNotificationMarkAllAsSeenDocument = gql`
    mutation onlineNotificationMarkAllAsSeen {
  onlineNotificationMarkAllAsSeen {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useOnlineNotificationMarkAllAsSeenMutation(options: VueApolloComposable.UseMutationOptions<Types.OnlineNotificationMarkAllAsSeenMutation, Types.OnlineNotificationMarkAllAsSeenMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.OnlineNotificationMarkAllAsSeenMutation, Types.OnlineNotificationMarkAllAsSeenMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.OnlineNotificationMarkAllAsSeenMutation, Types.OnlineNotificationMarkAllAsSeenMutationVariables>(OnlineNotificationMarkAllAsSeenDocument, options);
}
export type OnlineNotificationMarkAllAsSeenMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.OnlineNotificationMarkAllAsSeenMutation, Types.OnlineNotificationMarkAllAsSeenMutationVariables>;