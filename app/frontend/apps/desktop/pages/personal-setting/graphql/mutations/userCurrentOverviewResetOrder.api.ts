import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentOverviewResetOrderDocument = gql`
    mutation userCurrentOverviewResetOrder {
  userCurrentOverviewResetOrder {
    success
    overviews {
      id
      name
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentOverviewResetOrderMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables>(UserCurrentOverviewResetOrderDocument, options);
}
export type UserCurrentOverviewResetOrderMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables>;