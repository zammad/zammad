import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerAttributes.api';
import { KnowledgeBaseAnswerPolicyFragmentDoc } from '../fragments/knowledgeBaseAnswerPolicy.api';
import { KnowledgeBaseAnswerPreInfoFragmentDoc } from '../fragments/knowledgeBaseAnswerPreInfo.api';
import { KnowledgeBaseCategoryBreadcrumbFragmentDoc } from '../fragments/knowledgeBaseCategoryBreadcrumb.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerUpdateDocument = gql`
    mutation knowledgeBaseAnswerUpdate($answerId: ID!, $input: KnowledgeBaseUpdateAnswerInput!, $locale: String!, $meta: KnowledgeBaseAnswerUpdateMetaInput, $withBodyForEditing: Boolean = false, $withNavigation: Boolean = false) {
  knowledgeBaseAnswerUpdate(
    answerId: $answerId
    input: $input
    locale: $locale
    meta: $meta
  ) {
    answer {
      id
      ...knowledgeBaseAnswerAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${KnowledgeBaseAnswerAttributesFragmentDoc}
${KnowledgeBaseAnswerPolicyFragmentDoc}
${KnowledgeBaseAnswerPreInfoFragmentDoc}
${KnowledgeBaseCategoryBreadcrumbFragmentDoc}
${ErrorsFragmentDoc}`;
export function useKnowledgeBaseAnswerUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables>(KnowledgeBaseAnswerUpdateDocument, options);
}
export type KnowledgeBaseAnswerUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables>;