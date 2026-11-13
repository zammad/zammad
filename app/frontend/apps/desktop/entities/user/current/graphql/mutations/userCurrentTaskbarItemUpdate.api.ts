import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { TicketTaskbarTabAttributesFragmentDoc } from '../../../../../../../shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api';
import { KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc } from '../../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTaskbarTabAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemUpdateDocument = gql`
    mutation userCurrentTaskbarItemUpdate($id: ID!, $input: UserTaskbarItemInput!) {
  userCurrentTaskbarItemUpdate(id: $id, input: $input) {
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
export function useUserCurrentTaskbarItemUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTaskbarItemUpdateMutation, Types.UserCurrentTaskbarItemUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemUpdateMutation, Types.UserCurrentTaskbarItemUpdateMutationVariables>(UserCurrentTaskbarItemUpdateDocument, options);
}
export type UserCurrentTaskbarItemUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTaskbarItemUpdateMutation, Types.UserCurrentTaskbarItemUpdateMutationVariables>;