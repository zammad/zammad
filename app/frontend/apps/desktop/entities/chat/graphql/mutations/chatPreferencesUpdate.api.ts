import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatPreferencesAttributesFragmentDoc } from '../fragments/chatPreferencesAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChatPreferencesUpdateDocument = gql`
    mutation chatPreferencesUpdate($preferences: ChatPreferencesInput!) {
  chatPreferencesUpdate(preferences: $preferences) {
    preferences {
      ...chatPreferencesAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${ChatPreferencesAttributesFragmentDoc}
${ChatTopicAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useChatPreferencesUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables>(ChatPreferencesUpdateDocument, options);
}
export type ChatPreferencesUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables>;