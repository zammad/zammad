import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserPersonalSettingsFragmentDoc } from '../../../../../../shared/graphql/fragments/userPersonalSettings.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentNotificationPreferencesUpdateDocument = gql`
    mutation userCurrentNotificationPreferencesUpdate($groupIds: [ID!], $matrix: UserNotificationMatrixInput!, $sound: UserNotificationSoundInput!) {
  userCurrentNotificationPreferencesUpdate(
    groupIds: $groupIds
    matrix: $matrix
    sound: $sound
  ) {
    user {
      ...userPersonalSettings
    }
    errors {
      ...errors
    }
  }
}
    ${UserPersonalSettingsFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserCurrentNotificationPreferencesUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentNotificationPreferencesUpdateMutation, Types.UserCurrentNotificationPreferencesUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentNotificationPreferencesUpdateMutation, Types.UserCurrentNotificationPreferencesUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentNotificationPreferencesUpdateMutation, Types.UserCurrentNotificationPreferencesUpdateMutationVariables>(UserCurrentNotificationPreferencesUpdateDocument, options);
}
export type UserCurrentNotificationPreferencesUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentNotificationPreferencesUpdateMutation, Types.UserCurrentNotificationPreferencesUpdateMutationVariables>;