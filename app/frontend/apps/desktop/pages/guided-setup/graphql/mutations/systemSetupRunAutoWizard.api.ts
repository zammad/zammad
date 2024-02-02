import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SessionFragmentDoc } from '../../../../../../shared/graphql/fragments/session.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SystemSetupRunAutoWizardDocument = gql`
    mutation systemSetupRunAutoWizard($token: String) {
  systemSetupRunAutoWizard(token: $token) {
    session {
      ...session
    }
    errors {
      ...errors
    }
  }
}
    ${SessionFragmentDoc}
${ErrorsFragmentDoc}`;
export function useSystemSetupRunAutoWizardMutation(options: VueApolloComposable.UseMutationOptions<Types.SystemSetupRunAutoWizardMutation, Types.SystemSetupRunAutoWizardMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.SystemSetupRunAutoWizardMutation, Types.SystemSetupRunAutoWizardMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.SystemSetupRunAutoWizardMutation, Types.SystemSetupRunAutoWizardMutationVariables>(SystemSetupRunAutoWizardDocument, options);
}
export type SystemSetupRunAutoWizardMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.SystemSetupRunAutoWizardMutation, Types.SystemSetupRunAutoWizardMutationVariables>;