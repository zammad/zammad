import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CtiLogDoneUpdateDocument = gql`
    mutation ctiLogDoneUpdate($id: ID!, $done: Boolean!) {
  ctiLogDoneUpdate(id: $id, done: $done) {
    log {
      id
      done
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useCtiLogDoneUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.CtiLogDoneUpdateMutation, Types.CtiLogDoneUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.CtiLogDoneUpdateMutation, Types.CtiLogDoneUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.CtiLogDoneUpdateMutation, Types.CtiLogDoneUpdateMutationVariables>(CtiLogDoneUpdateDocument, options);
}
export type CtiLogDoneUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.CtiLogDoneUpdateMutation, Types.CtiLogDoneUpdateMutationVariables>;