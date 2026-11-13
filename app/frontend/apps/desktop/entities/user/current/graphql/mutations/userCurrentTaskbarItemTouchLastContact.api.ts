import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { TicketTaskbarTabAttributesFragmentDoc } from '../../../../../../../shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api';
import { KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc } from '../../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTaskbarTabAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemTouchLastContactDocument = gql`
    mutation userCurrentTaskbarItemTouchLastContact($id: ID!) {
  userCurrentTaskbarItemTouchLastContact(id: $id) {
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
export function useUserCurrentTaskbarItemTouchLastContactMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables>(UserCurrentTaskbarItemTouchLastContactDocument, options);
}
export type UserCurrentTaskbarItemTouchLastContactMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables>;