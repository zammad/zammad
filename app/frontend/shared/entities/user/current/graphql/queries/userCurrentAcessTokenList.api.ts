import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TokenAttributesFragmentDoc } from '../fragments/tokenAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentAccessTokenListDocument = gql`
    query userCurrentAccessTokenList {
  userCurrentAccessTokenList {
    ...tokenAttributes
  }
}
    ${TokenAttributesFragmentDoc}`;
export function useUserCurrentAccessTokenListQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>(UserCurrentAccessTokenListDocument, options);
}
export function useUserCurrentAccessTokenListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>(UserCurrentAccessTokenListDocument, options);
}
export type UserCurrentAccessTokenListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>;