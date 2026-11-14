import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../graphql/fragments/userAttributes.api';
import { UserPersonalSettingsFragmentDoc } from '../../../../graphql/fragments/userPersonalSettings.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserUpdateDocument = gql`
    mutation userUpdate($id: ID!, $input: UserInput!) {
  userUpdate(id: $id, input: $input) {
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
export function useUserUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.UserUpdateMutation, Types.UserUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>(UserUpdateDocument, options);
}
export type UserUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>;