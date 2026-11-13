import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { TicketTaskbarTabAttributesFragmentDoc } from '../../../../../../../shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api';
import { KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc } from '../../../../knowledge-base/graphql/fragments/knowledgeBaseAnswerTaskbarTabAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemListDocument = gql`
    query userCurrentTaskbarItemList($app: EnumTaskbarApp!) {
  userCurrentTaskbarItemList(app: $app) {
    ...userCurrentTaskbarItemAttributes
  }
}
    ${UserCurrentTaskbarItemAttributesFragmentDoc}
${TicketTaskbarTabAttributesFragmentDoc}
${KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc}`;
export function useUserCurrentTaskbarItemListQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>) {
  return VueApolloComposable.useQuery<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>(UserCurrentTaskbarItemListDocument, options);
}
export function useUserCurrentTaskbarItemListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>(UserCurrentTaskbarItemListDocument, options);
}
export type UserCurrentTaskbarItemListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>;