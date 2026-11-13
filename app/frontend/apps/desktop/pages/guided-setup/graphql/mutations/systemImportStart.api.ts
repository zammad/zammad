import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SystemImportStartDocument = gql`
    mutation systemImportStart {
  systemImportStart {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useSystemImportStartMutation(options: VueApolloComposable.useMutation.Options<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables>(SystemImportStartDocument, options);
}
export type SystemImportStartMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables>;