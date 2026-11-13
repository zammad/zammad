import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { TicketTaskbarTabAttributesFragmentDoc } from '../../../../../../../shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api';
import { KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc } from '../../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTaskbarTabAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemAddDocument = gql`
    mutation userCurrentTaskbarItemAdd($input: UserTaskbarItemInput!) {
  userCurrentTaskbarItemAdd(input: $input) {
    taskbarItem {
      ...userCurrentTaskbarItemAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${UserCurrentTaskbarItemAttributesFragmentDoc}
${TicketTaskbarTabAttributesFragmentDoc}
${KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserCurrentTaskbarItemAddMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables>(UserCurrentTaskbarItemAddDocument, options);
}
export type UserCurrentTaskbarItemAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables>;