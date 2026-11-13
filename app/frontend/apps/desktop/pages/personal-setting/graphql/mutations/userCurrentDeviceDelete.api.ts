import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentDeviceDeleteDocument = gql`
    mutation userCurrentDeviceDelete($deviceId: ID!) {
  userCurrentDeviceDelete(deviceId: $deviceId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentDeviceDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentDeviceDeleteMutation, Types.UserCurrentDeviceDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentDeviceDeleteMutation, Types.UserCurrentDeviceDeleteMutationVariables>(UserCurrentDeviceDeleteDocument, options);
}
export type UserCurrentDeviceDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentDeviceDeleteMutation, Types.UserCurrentDeviceDeleteMutationVariables>;