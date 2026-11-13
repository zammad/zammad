import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTaskbarItemDeleteDocument = gql`
    mutation userCurrentTaskbarItemDelete($id: ID!) {
  userCurrentTaskbarItemDelete(id: $id) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTaskbarItemDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTaskbarItemDeleteMutation, Types.UserCurrentTaskbarItemDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemDeleteMutation, Types.UserCurrentTaskbarItemDeleteMutationVariables>(UserCurrentTaskbarItemDeleteDocument, options);
}
export type UserCurrentTaskbarItemDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTaskbarItemDeleteMutation, Types.UserCurrentTaskbarItemDeleteMutationVariables>;