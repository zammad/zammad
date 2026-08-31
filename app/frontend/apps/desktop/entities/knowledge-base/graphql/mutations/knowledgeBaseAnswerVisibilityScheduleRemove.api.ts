import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerVisibilityScheduleRemoveDocument = gql`
    mutation knowledgeBaseAnswerVisibilityScheduleRemove($answerId: ID!, $visibility: EnumKnowledgeBaseSchedulableVisibility!) {
  knowledgeBaseAnswerVisibilityScheduleRemove(
    answerId: $answerId
    visibility: $visibility
  ) {
    answer {
      id
      visibilitySchedules {
        visibility
        scheduledAt
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseAnswerVisibilityScheduleRemoveMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutation, Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutation, Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutation, Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutationVariables>(KnowledgeBaseAnswerVisibilityScheduleRemoveDocument, options);
}
export type KnowledgeBaseAnswerVisibilityScheduleRemoveMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutation, Types.KnowledgeBaseAnswerVisibilityScheduleRemoveMutationVariables>;