import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useSystemImportStartMutation(options: VueApolloComposable.UseMutationOptions<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables>(SystemImportStartDocument, options);
}
export type SystemImportStartMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables>;