import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserCurrentOverviewUpdateLastUsedMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables>(UserCurrentOverviewUpdateLastUsedDocument, options);
}
export type UserCurrentOverviewUpdateLastUsedMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentOverviewUpdateLastUsedMutation, Types.UserCurrentOverviewUpdateLastUsedMutationVariables>;