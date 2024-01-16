import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SystemSetupUnlockDocument = gql`
    mutation systemSetupUnlock($value: String!) {
  systemSetupUnlock(value: $value) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useSystemSetupUnlockMutation(options: VueApolloComposable.UseMutationOptions<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables>(SystemSetupUnlockDocument, options);
}
export type SystemSetupUnlockMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables>;