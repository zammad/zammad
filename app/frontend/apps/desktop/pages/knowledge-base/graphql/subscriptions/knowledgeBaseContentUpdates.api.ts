import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useKnowledgeBaseContentUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables>(KnowledgeBaseContentUpdatesDocument, {}, options);
}
export type KnowledgeBaseContentUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.KnowledgeBaseContentUpdatesSubscription, Types.KnowledgeBaseContentUpdatesSubscriptionVariables>;