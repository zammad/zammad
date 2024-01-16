import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const GuidedSetupSetSystemInformationDocument = gql`
    mutation guidedSetupSetSystemInformation($input: SystemInformation!) {
  guidedSetupSetSystemInformation(input: $input) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useGuidedSetupSetSystemInformationMutation(options: VueApolloComposable.UseMutationOptions<Types.GuidedSetupSetSystemInformationMutation, Types.GuidedSetupSetSystemInformationMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.GuidedSetupSetSystemInformationMutation, Types.GuidedSetupSetSystemInformationMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.GuidedSetupSetSystemInformationMutation, Types.GuidedSetupSetSystemInformationMutationVariables>(GuidedSetupSetSystemInformationDocument, options);
}
export type GuidedSetupSetSystemInformationMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.GuidedSetupSetSystemInformationMutation, Types.GuidedSetupSetSystemInformationMutationVariables>;