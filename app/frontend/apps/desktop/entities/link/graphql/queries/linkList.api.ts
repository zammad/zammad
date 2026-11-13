import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerTranslationFragmentDoc } from '../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const LinkListDocument = gql`
    query linkList($objectId: ID!, $targetType: String!) {
  linkList(objectId: $objectId, targetType: $targetType) {
    type
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
  }
}
    ${KnowledgeBaseAnswerTranslationFragmentDoc}`;
export function useLinkListQuery(options: VueApolloComposable.useQuery.Options<Types.LinkListQuery, Types.LinkListQueryVariables>) {
  return VueApolloComposable.useQuery<Types.LinkListQuery, Types.LinkListQueryVariables>(LinkListDocument, options);
}
export function useLinkListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.LinkListQuery, Types.LinkListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.LinkListQuery, Types.LinkListQueryVariables>(LinkListDocument, options);
}
export type LinkListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.LinkListQuery, Types.LinkListQueryVariables>;