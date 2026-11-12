import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ApplicationBuildChecksumDocument = gql`
    query applicationBuildChecksum {
  applicationBuildChecksum
}
    `;
export function useApplicationBuildChecksumQuery(options: VueApolloComposable.useQuery.Options<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>(ApplicationBuildChecksumDocument, options);
}
export function useApplicationBuildChecksumLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>(ApplicationBuildChecksumDocument, options);
}
export type ApplicationBuildChecksumQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>;