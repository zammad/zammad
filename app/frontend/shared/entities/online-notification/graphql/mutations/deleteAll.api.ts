import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OnlineNotificationDeleteAllDocument = gql`
    mutation onlineNotificationDeleteAll {
  onlineNotificationDeleteAll {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useOnlineNotificationDeleteAllMutation(options: VueApolloComposable.useMutation.Options<Types.OnlineNotificationDeleteAllMutation, Types.OnlineNotificationDeleteAllMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.OnlineNotificationDeleteAllMutation, Types.OnlineNotificationDeleteAllMutationVariables>(OnlineNotificationDeleteAllDocument, options);
}
export type OnlineNotificationDeleteAllMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.OnlineNotificationDeleteAllMutation, Types.OnlineNotificationDeleteAllMutationVariables>;