import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SystemImportConfigurationDocument = gql`
    mutation systemImportConfiguration($configuration: SystemImportConfigurationInput!) {
  systemImportConfiguration(configuration: $configuration) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useSystemImportConfigurationMutation(options: VueApolloComposable.useMutation.Options<Types.SystemImportConfigurationMutation, Types.SystemImportConfigurationMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.SystemImportConfigurationMutation, Types.SystemImportConfigurationMutationVariables>(SystemImportConfigurationDocument, options);
}
export type SystemImportConfigurationMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.SystemImportConfigurationMutation, Types.SystemImportConfigurationMutationVariables>;