import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../fragments/organizationAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
${ErrorsFragmentDoc}`;
export function useOrganizationUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables>(OrganizationUpdateDocument, options);
}
export type OrganizationUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.OrganizationUpdateMutation, Types.OrganizationUpdateMutationVariables>;