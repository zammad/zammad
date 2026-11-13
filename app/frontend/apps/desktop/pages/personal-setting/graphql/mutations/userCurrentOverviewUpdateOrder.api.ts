import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentOverviewUpdateOrderDocument = gql`
    mutation userCurrentOverviewUpdateOrder($overviewIds: [ID!]!) {
  userCurrentOverviewUpdateOrder(overviewIds: $overviewIds) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentOverviewUpdateOrderMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentOverviewUpdateOrderMutation, Types.UserCurrentOverviewUpdateOrderMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentOverviewUpdateOrderMutation, Types.UserCurrentOverviewUpdateOrderMutationVariables>(UserCurrentOverviewUpdateOrderDocument, options);
}
export type UserCurrentOverviewUpdateOrderMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentOverviewUpdateOrderMutation, Types.UserCurrentOverviewUpdateOrderMutationVariables>;