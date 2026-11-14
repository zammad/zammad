import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../graphql/fragments/userAttributes.api';
import { UserPersonalSettingsFragmentDoc } from '../../../../graphql/fragments/userPersonalSettings.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserAddDocument = gql`
    mutation userAdd($input: UserInput!, $sendInvite: Boolean) {
  userAdd(input: $input, sendInvite: $sendInvite) {
    user {
      ...userAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${UserAttributesFragmentDoc}
${UserPersonalSettingsFragmentDoc}
${ObjectAttributeValuesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserAddMutation(options: VueApolloComposable.useMutation.Options<Types.UserAddMutation, Types.UserAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserAddMutation, Types.UserAddMutationVariables>(UserAddDocument, options);
}
export type UserAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserAddMutation, Types.UserAddMutationVariables>;