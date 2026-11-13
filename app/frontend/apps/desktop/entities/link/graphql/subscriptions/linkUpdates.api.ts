import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerTranslationFragmentDoc } from '../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const LinkUpdatesDocument = gql`
    subscription linkUpdates($objectId: ID!, $targetType: String!) {
  linkUpdates(objectId: $objectId, targetType: $targetType) {
    links {
      item {
        __typename
        ... on Ticket {
          id
          internalId
          title
          state {
            id
            name
          }
          stateColorCode
        }
        ... on KnowledgeBaseAnswerTranslation {
          ...knowledgeBaseAnswerTranslation
        }
      }
      type
    }
  }
}
    ${KnowledgeBaseAnswerTranslationFragmentDoc}`;
export function useLinkUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables>(LinkUpdatesDocument, options);
}
export type LinkUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables>;