import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OnlineNotificationSeenDocument = gql`
    mutation onlineNotificationSeen($objectId: ID!) {
  onlineNotificationSeen(objectId: $objectId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useOnlineNotificationSeenMutation(options: VueApolloComposable.useMutation.Options<Types.OnlineNotificationSeenMutation, Types.OnlineNotificationSeenMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.OnlineNotificationSeenMutation, Types.OnlineNotificationSeenMutationVariables>(OnlineNotificationSeenDocument, options);
}
export type OnlineNotificationSeenMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.OnlineNotificationSeenMutation, Types.OnlineNotificationSeenMutationVariables>;