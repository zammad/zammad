import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerUpdatesDocument = gql`
    subscription knowledgeBaseAnswerUpdates($answerId: ID!, $locale: String, $initial: Boolean = false) {
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
    ${KnowledgeBaseAnswerAttributesFragmentDoc}`;
export function useKnowledgeBaseAnswerUpdatesSubscription(variables: Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>(KnowledgeBaseAnswerUpdatesDocument, variables, options);
}
export type KnowledgeBaseAnswerUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.KnowledgeBaseAnswerUpdatesSubscription, Types.KnowledgeBaseAnswerUpdatesSubscriptionVariables>;