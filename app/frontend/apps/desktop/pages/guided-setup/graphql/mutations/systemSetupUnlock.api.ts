import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useSystemSetupUnlockMutation(options: VueApolloComposable.useMutation.Options<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables>(SystemSetupUnlockDocument, options);
}
export type SystemSetupUnlockMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables>;