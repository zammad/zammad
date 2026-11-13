import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useLinkRemoveMutation(options: VueApolloComposable.useMutation.Options<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables>(LinkRemoveDocument, options);
}
export type LinkRemoveMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.LinkRemoveMutation, Types.LinkRemoveMutationVariables>;