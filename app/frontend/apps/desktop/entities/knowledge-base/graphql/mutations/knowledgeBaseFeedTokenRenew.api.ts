import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseFeedAttributesFragmentDoc } from '../fragments/knowledgeBaseFeedAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseFeedTokenRenewDocument = gql`
    mutation knowledgeBaseFeedTokenRenew($categoryId: ID, $locale: String) {
  knowledgeBaseFeedTokenRenew(categoryId: $categoryId, locale: $locale) {
    feed {
      ...knowledgeBaseFeedAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${KnowledgeBaseFeedAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useKnowledgeBaseFeedTokenRenewMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseFeedTokenRenewMutation, Types.KnowledgeBaseFeedTokenRenewMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseFeedTokenRenewMutation, Types.KnowledgeBaseFeedTokenRenewMutationVariables>(KnowledgeBaseFeedTokenRenewDocument, options);
}
export type KnowledgeBaseFeedTokenRenewMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseFeedTokenRenewMutation, Types.KnowledgeBaseFeedTokenRenewMutationVariables>;