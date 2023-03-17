import * as Types from '../../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountAvatarActiveDocument = gql`
    query accountAvatarActive {
  accountAvatarActive {
    id
    default
    deletable
    initial
    imageFull
    imageResize
    createdAt
    updatedAt
  }
}
    `;
export function useAccountAvatarActiveQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>(AccountAvatarActiveDocument, {}, options);
}
export function useAccountAvatarActiveLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>(AccountAvatarActiveDocument, {}, options);
}
export type AccountAvatarActiveQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>;