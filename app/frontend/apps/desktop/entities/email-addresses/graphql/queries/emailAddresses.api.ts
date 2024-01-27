import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const EmailAddressesDocument = gql`
    query emailAddresses($onlyActive: Boolean = false) {
  emailAddresses(onlyActive: $onlyActive) {
    name
    email
    active
  }
}
    `;
export function useEmailAddressesQuery(variables: Types.EmailAddressesQueryVariables | VueCompositionApi.Ref<Types.EmailAddressesQueryVariables> | ReactiveFunction<Types.EmailAddressesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>(EmailAddressesDocument, variables, options);
}
export function useEmailAddressesLazyQuery(variables: Types.EmailAddressesQueryVariables | VueCompositionApi.Ref<Types.EmailAddressesQueryVariables> | ReactiveFunction<Types.EmailAddressesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>(EmailAddressesDocument, variables, options);
}
export type EmailAddressesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.EmailAddressesQuery, Types.EmailAddressesQueryVariables>;