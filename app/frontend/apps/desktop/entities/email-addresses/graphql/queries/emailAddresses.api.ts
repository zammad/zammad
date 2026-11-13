import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const EmailAddressesDocument = gql`
    query emailAddresses($onlyActive: Boolean = false) {
  emailAddresses(onlyActive: $onlyActive) {
    name
    email
    active
  }
}
    `;
export function useEmailAddressesQuery(options: VueApolloComposable.useQuery.Options<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>(EmailAddressesDocument, options);
}
export function useEmailAddressesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>(EmailAddressesDocument, options);
}
export type EmailAddressesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>;