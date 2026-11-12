import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SessionFragmentDoc } from '../fragments/session.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SessionDocument = gql`
    query session {
  session {
    ...session
  }
}
    ${SessionFragmentDoc}`;
export function useSessionQuery(options: VueApolloComposable.useQuery.Options<Types.SessionQuery, Types.SessionQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.SessionQuery, Types.SessionQueryVariables>(SessionDocument, options);
}
export function useSessionLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.SessionQuery, Types.SessionQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.SessionQuery, Types.SessionQueryVariables>(SessionDocument, options);
}
export type SessionQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.SessionQuery, Types.SessionQueryVariables>;