import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentCallerNotificationUpdateDocument = gql`
    mutation userCurrentCallerNotificationUpdate($enabled: Boolean!) {
  userCurrentCallerNotificationUpdate(enabled: $enabled) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentCallerNotificationUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables>(UserCurrentCallerNotificationUpdateDocument, options);
}
export type UserCurrentCallerNotificationUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables>;