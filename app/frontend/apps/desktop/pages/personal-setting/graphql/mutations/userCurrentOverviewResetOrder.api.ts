import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserCurrentOverviewResetOrderMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables>(UserCurrentOverviewResetOrderDocument, options);
}
export type UserCurrentOverviewResetOrderMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentOverviewResetOrderMutation, Types.UserCurrentOverviewResetOrderMutationVariables>;