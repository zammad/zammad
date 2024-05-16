import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserPersonalSettingsFragmentDoc } from '../../../../../../shared/graphql/fragments/userPersonalSettings.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentNotificationPreferencesResetDocument = gql`
    mutation userCurrentNotificationPreferencesReset {
  userCurrentNotificationPreferencesReset {
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
export function useUserCurrentNotificationPreferencesResetMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables>(UserCurrentNotificationPreferencesResetDocument, options);
}
export type UserCurrentNotificationPreferencesResetMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables>;