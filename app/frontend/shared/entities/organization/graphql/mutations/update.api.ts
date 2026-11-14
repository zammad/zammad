import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../fragments/organizationAttributes.api';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const OrganizationUpdateDocument = gql`
    mutation organizationUpdate($id: ID!, $input: OrganizationInput!) {
  organizationUpdate(id: $id, input: $input) {
    organization {
      ...organizationAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${OrganizationAttributesFragmentDoc}
${ObjectAttributeValuesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useOrganizationUpdateMutation(options: VueApolloComposable.useMutation.Options<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables>(OrganizationUpdateDocument, options);
}
export type OrganizationUpdateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables>;