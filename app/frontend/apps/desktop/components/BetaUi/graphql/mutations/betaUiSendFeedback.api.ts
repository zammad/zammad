import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const BetaUiSendFeedbackDocument = gql`
    mutation betaUiSendFeedback($input: BetaUiFeedbackInput!) {
  betaUiSendFeedback(input: $input) {
    success
  }
}
    `;
export function useBetaUiSendFeedbackMutation(options: VueApolloComposable.UseMutationOptions<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables>(BetaUiSendFeedbackDocument, options);
}
export type BetaUiSendFeedbackMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.BetaUiSendFeedbackMutation, Types.BetaUiSendFeedbackMutationVariables>;