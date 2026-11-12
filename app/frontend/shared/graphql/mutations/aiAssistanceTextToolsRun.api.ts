import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useAiAssistanceTextToolsRunMutation(options: VueApolloComposable.useMutation.Options<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables>(AiAssistanceTextToolsRunDocument, options);
}
export type AiAssistanceTextToolsRunMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.AiAssistanceTextToolsRunMutation, Types.AiAssistanceTextToolsRunMutationVariables>;