import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountAvatarSelectDocument = gql`
    mutation accountAvatarSelect($id: ID!) {
  accountAvatarSelect(id: $id) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountAvatarSelectMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountAvatarSelectMutation, Types.AccountAvatarSelectMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountAvatarSelectMutation, Types.AccountAvatarSelectMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountAvatarSelectMutation, Types.AccountAvatarSelectMutationVariables>(AccountAvatarSelectDocument, options);
}
export type AccountAvatarSelectMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountAvatarSelectMutation, Types.AccountAvatarSelectMutationVariables>;