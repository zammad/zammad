import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LinkListDocument = gql`
    query linkList($objectId: ID!, $targetType: String!) {
  linkList(objectId: $objectId, targetType: $targetType) {
    type
    item {
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
        id
      }
    }
  }
}
    `;
export function useLinkListQuery(variables: Types.LinkListQueryVariables | VueCompositionApi.Ref<Types.LinkListQueryVariables> | ReactiveFunction<Types.LinkListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.LinkListQuery, Types.LinkListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.LinkListQuery, Types.LinkListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.LinkListQuery, Types.LinkListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.LinkListQuery, Types.LinkListQueryVariables>(LinkListDocument, variables, options);
}
export function useLinkListLazyQuery(variables?: Types.LinkListQueryVariables | VueCompositionApi.Ref<Types.LinkListQueryVariables> | ReactiveFunction<Types.LinkListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.LinkListQuery, Types.LinkListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.LinkListQuery, Types.LinkListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.LinkListQuery, Types.LinkListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.LinkListQuery, Types.LinkListQueryVariables>(LinkListDocument, variables, options);
}
export type LinkListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.LinkListQuery, Types.LinkListQueryVariables>;