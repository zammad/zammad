import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentOverviewUpdateLastUsedDocument = gql`
    mutation userCurrentOverviewUpdateLastUsed($overviewsLastUsed: [UserCurrentOverviewLastUsed!]!) {
  userCurrentOverviewUpdateLastUsed(overviewsLastUsed: $overviewsLastUsed) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentOverviewUpdateLastUsedMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables>(UserCurrentOverviewUpdateLastUsedDocument, options);
}
export type UserCurrentOverviewUpdateLastUsedMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables>;