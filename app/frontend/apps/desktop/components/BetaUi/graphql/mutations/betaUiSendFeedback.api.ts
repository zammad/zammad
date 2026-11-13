import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const BetaUiSendFeedbackDocument = gql`
    mutation betaUiSendFeedback($input: BetaUiFeedbackInput!) {
  betaUiSendFeedback(input: $input) {
    success
  }
}
    `;
export function useBetaUiSendFeedbackMutation(options: VueApolloComposable.useMutation.Options<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables>(BetaUiSendFeedbackDocument, options);
}
export type BetaUiSendFeedbackMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables>;