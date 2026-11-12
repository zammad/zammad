import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ObjectManagerFrontendAttributesDocument = gql`
    query objectManagerFrontendAttributes($object: EnumObjectManagerObjects!) {
  objectManagerFrontendAttributes(object: $object) {
    attributes {
      name
      display
      dataType
      dataOption
      isInternal
      screens
    }
    screens {
      name
      attributes
    }
  }
}
    `;
export function useObjectManagerFrontendAttributesQuery(options: VueApolloComposable.useQuery.Options<Types.ObjectManagerFrontendAttributesQuery, Types.ObjectManagerFrontendAttributesQueryVariables>) {
  return VueApolloComposable.useQuery<Types.ObjectManagerFrontendAttributesQuery, Types.ObjectManagerFrontendAttributesQueryVariables>(ObjectManagerFrontendAttributesDocument, options);
}
export function useObjectManagerFrontendAttributesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.ObjectManagerFrontendAttributesQuery, Types.ObjectManagerFrontendAttributesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.ObjectManagerFrontendAttributesQuery, Types.ObjectManagerFrontendAttributesQueryVariables>(ObjectManagerFrontendAttributesDocument, options);
}
export type ObjectManagerFrontendAttributesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.ObjectManagerFrontendAttributesQuery, Types.ObjectManagerFrontendAttributesQueryVariables>;