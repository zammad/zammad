import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ApplicationConfigDocument = gql`
    query applicationConfig {
  applicationConfig {
    key
    value
  }
}
    `;
export function useApplicationConfigQuery(options: VueApolloComposable.useQuery.Options<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>(ApplicationConfigDocument, options);
}
export function useApplicationConfigLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>(ApplicationConfigDocument, options);
}
export type ApplicationConfigQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>;