import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserPersonalSettingsFragmentDoc } from '../../../../../../shared/graphql/fragments/userPersonalSettings.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentNotificationPreferencesResetMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables>(UserCurrentNotificationPreferencesResetDocument, options);
}
export type UserCurrentNotificationPreferencesResetMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables>;