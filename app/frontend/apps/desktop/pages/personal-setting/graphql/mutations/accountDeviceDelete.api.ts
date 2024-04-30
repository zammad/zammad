import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountDeviceDeleteDocument = gql`
    mutation accountDeviceDelete($deviceId: ID!) {
  accountDeviceDelete(deviceId: $deviceId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountDeviceDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountDeviceDeleteMutation, Types.AccountDeviceDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountDeviceDeleteMutation, Types.AccountDeviceDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountDeviceDeleteMutation, Types.AccountDeviceDeleteMutationVariables>(AccountDeviceDeleteDocument, options);
}
export type AccountDeviceDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountDeviceDeleteMutation, Types.AccountDeviceDeleteMutationVariables>;