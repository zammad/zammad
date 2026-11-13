import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseContentUpdatesDocument = gql`
    subscription knowledgeBaseContentUpdates {
  knowledgeBaseContentUpdates {
    knowledgeBase {
      id
    }
    affectedCategoryIds
  }
}
    `;
export function useKnowledgeBaseContentUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables>(KnowledgeBaseContentUpdatesDocument, options);
}
export type KnowledgeBaseContentUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables>;