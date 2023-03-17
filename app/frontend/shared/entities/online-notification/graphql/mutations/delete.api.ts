import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OnlineNotificationDeleteDocument = gql`
    mutation onlineNotificationDelete($onlineNotificationId: ID!) {
  onlineNotificationDelete(onlineNotificationId: $onlineNotificationId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useOnlineNotificationDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables>(OnlineNotificationDeleteDocument, options);
}
export type OnlineNotificationDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.OnlineNotificationDeleteMutation, Types.OnlineNotificationDeleteMutationVariables>;