import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketAiRelatedKnowledgeBaseAnswersDocument = gql`
    query ticketAIRelatedKnowledgeBaseAnswers($ticketId: ID!) {
  ticketAIRelatedKnowledgeBaseAnswers(ticketId: $ticketId) {
    pending
    answers {
      score
      translation {
        id
        title
        answer {
          id
          category {
            knowledgeBase {
              id
            }
          }
        }
        kbLocale {
          systemLocale {
            locale
          }
        }
      }
    }
  }
}
    `;
export function useTicketAiRelatedKnowledgeBaseAnswersQuery(variables: Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables | VueCompositionApi.Ref<Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables> | ReactiveFunction<Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>(TicketAiRelatedKnowledgeBaseAnswersDocument, variables, options);
}
export function useTicketAiRelatedKnowledgeBaseAnswersLazyQuery(variables?: Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables | VueCompositionApi.Ref<Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables> | ReactiveFunction<Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>(TicketAiRelatedKnowledgeBaseAnswersDocument, variables, options);
}
export type TicketAiRelatedKnowledgeBaseAnswersQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>;