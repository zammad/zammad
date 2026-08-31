import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentKnowledgeBaseAnswerScreenBehaviorDocument = gql`
    mutation userCurrentKnowledgeBaseAnswerScreenBehavior($screen: EnumKnowledgeBaseAnswerScreen!, $behavior: EnumKnowledgeBaseAnswerScreenBehavior!) {
  userCurrentKnowledgeBaseAnswerScreenBehavior(
    screen: $screen
    behavior: $behavior
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentKnowledgeBaseAnswerScreenBehaviorMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutation, Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutation, Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutation, Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutationVariables>(UserCurrentKnowledgeBaseAnswerScreenBehaviorDocument, options);
}
export type UserCurrentKnowledgeBaseAnswerScreenBehaviorMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutation, Types.UserCurrentKnowledgeBaseAnswerScreenBehaviorMutationVariables>;