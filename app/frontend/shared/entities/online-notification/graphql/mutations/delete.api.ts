import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OnlineNotificationDeleteDocument = gql`
    mutation onlineNotificationDelete($onlineNotificationId: ID!) {
  onlineNotificationDelete(onlineNotificationId: $onlineNotificationId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useOnlineNotificationDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables>(OnlineNotificationDeleteDocument, options);
}
export type OnlineNotificationDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables>;