import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentCalendarSubscriptionUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables>(UserCurrentCalendarSubscriptionUpdateDocument, options);
}
export type UserCurrentCalendarSubscriptionUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables>;