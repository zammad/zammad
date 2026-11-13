import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SystemSetupLockDocument = gql`
    mutation systemSetupLock($ttl: Int) {
  systemSetupLock(ttl: $ttl) {
    resource
    value
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useSystemSetupLockMutation(options: VueApolloComposable.useMutation.Options<Types.SystemSetupLockMutation, Types.SystemSetupLockMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.SystemSetupLockMutation, Types.SystemSetupLockMutationVariables>(SystemSetupLockDocument, options);
}
export type SystemSetupLockMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.SystemSetupLockMutation, Types.SystemSetupLockMutationVariables>;