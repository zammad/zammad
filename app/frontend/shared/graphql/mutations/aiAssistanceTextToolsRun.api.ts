import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AiAssistanceTextToolsRunDocument = gql`
    mutation aiAssistanceTextToolsRun($input: String!, $textToolId: ID!, $templateRenderContext: TemplateRenderContextInput!) {
  aiAssistanceTextToolsRun(
    input: $input
    textToolId: $textToolId
    templateRenderContext: $templateRenderContext
  ) {
    output
  }
}
    `;
export function useAiAssistanceTextToolsRunMutation(options: VueApolloComposable.UseMutationOptions<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables>(AiAssistanceTextToolsRunDocument, options);
}
export type AiAssistanceTextToolsRunMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables>;