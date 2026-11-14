import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OrganizationNoteUpdateDocument = gql`
    mutation organizationNoteUpdate($id: ID!, $note: String!) {
  organizationNoteUpdate(id: $id, note: $note) {
    organization {
      note
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useOrganizationNoteUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.OrganizationNoteUpdateMutation, Types.OrganizationNoteUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.OrganizationNoteUpdateMutation, Types.OrganizationNoteUpdateMutationVariables>(OrganizationNoteUpdateDocument, options);
}
export type OrganizationNoteUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.OrganizationNoteUpdateMutation, Types.OrganizationNoteUpdateMutationVariables>;