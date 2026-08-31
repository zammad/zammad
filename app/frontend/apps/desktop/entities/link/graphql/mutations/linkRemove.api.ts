import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LinkRemoveDocument = gql`
    mutation linkRemove($input: LinkInput!) {
  linkRemove(input: $input) {
    success
    errors {
      message
      field
    }
  }
}
    `;
export function useLinkRemoveMutation(options: VueApolloComposable.UseMutationOptions<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables>(LinkRemoveDocument, options);
}
export type LinkRemoveMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables>;