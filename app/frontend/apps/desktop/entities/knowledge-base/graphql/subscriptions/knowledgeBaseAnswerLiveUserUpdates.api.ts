import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerLiveUserAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerLiveUserAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerLiveUserUpdatesDocument = gql`
    subscription knowledgeBaseAnswerLiveUserUpdates($key: String!, $app: EnumTaskbarApp!) {
  knowledgeBaseAnswerLiveUserUpdates(key: $key, app: $app) {
    liveUsers {
      ...knowledgeBaseAnswerLiveUserAttributes
    }
  }
}
    ${KnowledgeBaseAnswerLiveUserAttributesFragmentDoc}`;
export function useKnowledgeBaseAnswerLiveUserUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>(KnowledgeBaseAnswerLiveUserUpdatesDocument, options);
}
export type KnowledgeBaseAnswerLiveUserUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription, Types.KnowledgeBaseAnswerLiveUserUpdatesSubscriptionVariables>;