import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentAvatarSelectDocument = gql`
    mutation userCurrentAvatarSelect($id: ID!) {
  userCurrentAvatarSelect(id: $id) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentAvatarSelectMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables>(UserCurrentAvatarSelectDocument, options);
}
export type UserCurrentAvatarSelectMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables>;