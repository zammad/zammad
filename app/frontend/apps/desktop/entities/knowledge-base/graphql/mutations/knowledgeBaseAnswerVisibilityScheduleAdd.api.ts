import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerVisibilityScheduleAddDocument = gql`
    mutation knowledgeBaseAnswerVisibilityScheduleAdd($answerId: ID!, $visibility: EnumKnowledgeBaseSchedulableVisibility!, $scheduledAt: ISO8601DateTime!) {
  knowledgeBaseAnswerVisibilityScheduleAdd(
    answerId: $answerId
    visibility: $visibility
    scheduledAt: $scheduledAt
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
export function useKnowledgeBaseAnswerVisibilityScheduleAddMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerVisibilityScheduleAddMutation, Types.KnowledgeBaseAnswerVisibilityScheduleAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseAnswerVisibilityScheduleAddMutation, Types.KnowledgeBaseAnswerVisibilityScheduleAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerVisibilityScheduleAddMutation, Types.KnowledgeBaseAnswerVisibilityScheduleAddMutationVariables>(KnowledgeBaseAnswerVisibilityScheduleAddDocument, options);
}
export type KnowledgeBaseAnswerVisibilityScheduleAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseAnswerVisibilityScheduleAddMutation, Types.KnowledgeBaseAnswerVisibilityScheduleAddMutationVariables>;