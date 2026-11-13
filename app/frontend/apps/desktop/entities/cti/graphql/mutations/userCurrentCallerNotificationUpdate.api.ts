import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentCallerNotificationUpdateDocument = gql`
    mutation userCurrentCallerNotificationUpdate($enabled: Boolean!) {
  userCurrentCallerNotificationUpdate(enabled: $enabled) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentCallerNotificationUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables>(UserCurrentCallerNotificationUpdateDocument, options);
}
export type UserCurrentCallerNotificationUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables>;