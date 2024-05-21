import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentCalendarSubscriptionUpdateDocument = gql`
    mutation userCurrentCalendarSubscriptionUpdate($input: UserCalendarSubscriptionsConfigInput!) {
  userCurrentCalendarSubscriptionUpdate(input: $input) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentCalendarSubscriptionUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables>(UserCurrentCalendarSubscriptionUpdateDocument, options);
}
export type UserCurrentCalendarSubscriptionUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables>;