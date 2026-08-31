import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerLiveUserAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerLiveUserAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerLiveUserUpdatesDocument = gql`
    subscription knowledgeBaseAnswerLiveUserUpdates($key: String!, $app: EnumTaskbarApp!) {
  knowledgeBaseAnswerLiveUserUpdates(key: $key, app: $app) {
    liveUsers {
      ...knowledgeBaseAnswerLiveUserAttributes
    }
  }
}
    ${KnowledgeBaseAnswerLiveUserAttributesFragmentDoc}`;
export function useKnowledgeBaseAnswerLiveUserUpdatesSubscription(variables: Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>(KnowledgeBaseAnswerLiveUserUpdatesDocument, variables, options);
}
export type KnowledgeBaseAnswerLiveUserUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>;