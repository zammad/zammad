import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ChatPreferencesAttributesFragmentDoc } from '../fragments/chatPreferencesAttributes.api';
import { ChatTopicAttributesFragmentDoc } from '../fragments/chatTopicAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useChatPreferencesUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables>(ChatPreferencesUpdateDocument, options);
}
export type ChatPreferencesUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables>;