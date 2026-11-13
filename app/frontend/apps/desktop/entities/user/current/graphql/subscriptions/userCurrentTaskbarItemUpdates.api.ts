import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { TicketTaskbarTabAttributesFragmentDoc } from '../../../../../../../shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api';
import { KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc } from '../../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTaskbarTabAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemUpdatesDocument = gql`
    subscription userCurrentTaskbarItemUpdates($app: EnumTaskbarApp!) {
  userCurrentTaskbarItemUpdates(app: $app) {
    addItem {
      ...userCurrentTaskbarItemAttributes
    }
    updateItem {
      ...userCurrentTaskbarItemAttributes
    }
    removeItem
  }
}
    ${UserCurrentTaskbarItemAttributesFragmentDoc}
${TicketTaskbarTabAttributesFragmentDoc}
${KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc}`;
export function useUserCurrentTaskbarItemUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>(UserCurrentTaskbarItemUpdatesDocument, options);
}
export type UserCurrentTaskbarItemUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.UserCurrentTaskbarItemUpdatesSubscription, Types.UserCurrentTaskbarItemUpdatesSubscriptionVariables>;