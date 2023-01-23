import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountAvatarDeleteDocument = gql`
    mutation accountAvatarDelete($id: ID!) {
  accountAvatarDelete(id: $id) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountAvatarDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountAvatarDeleteMutation, Types.AccountAvatarDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountAvatarDeleteMutation, Types.AccountAvatarDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountAvatarDeleteMutation, Types.AccountAvatarDeleteMutationVariables>(AccountAvatarDeleteDocument, options);
}
export type AccountAvatarDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountAvatarDeleteMutation, Types.AccountAvatarDeleteMutationVariables>;