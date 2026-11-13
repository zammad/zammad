import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerAttributes.api';
import { KnowledgeBaseAnswerPolicyFragmentDoc } from '../fragments/knowledgeBaseAnswerPolicy.api';
import { KnowledgeBaseAnswerPreInfoFragmentDoc } from '../fragments/knowledgeBaseAnswerPreInfo.api';
import { KnowledgeBaseCategoryBreadcrumbFragmentDoc } from '../fragments/knowledgeBaseCategoryBreadcrumb.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerUpdatesDocument = gql`
    subscription knowledgeBaseAnswerUpdates($answerId: ID!, $locale: String, $initial: Boolean = false, $withBodyForEditing: Boolean = false, $withNavigation: Boolean = false) {
  knowledgeBaseAnswerUpdates(
    answerId: $answerId
    locale: $locale
    initial: $initial
  ) {
    answer {
      id
      ...knowledgeBaseAnswerAttributes
    }
  }
}
    ${KnowledgeBaseAnswerAttributesFragmentDoc}
${KnowledgeBaseAnswerPolicyFragmentDoc}
${KnowledgeBaseAnswerPreInfoFragmentDoc}
${KnowledgeBaseCategoryBreadcrumbFragmentDoc}`;
export function useKnowledgeBaseAnswerUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>(KnowledgeBaseAnswerUpdatesDocument, options);
}
export type KnowledgeBaseAnswerUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>;