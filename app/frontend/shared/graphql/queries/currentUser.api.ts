import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { CurrentUserAttributesFragmentDoc } from '../fragments/currentUserAttributes.api';
import { UserAttributesFragmentDoc } from '../fragments/userAttributes.api';
import { UserPersonalSettingsFragmentDoc } from '../fragments/userPersonalSettings.api';
import { ObjectAttributeValuesFragmentDoc } from '../fragments/objectAttributeValues.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const CurrentUserDocument = gql`
    query currentUser {
  currentUser {
    ...currentUserAttributes
  }
}
    ${CurrentUserAttributesFragmentDoc}
${UserAttributesFragmentDoc}
${UserPersonalSettingsFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;
export function useCurrentUserQuery(options: VueApolloComposable.useQuery.Options<Types.CurrentUserQuery, Types.CurrentUserQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>(CurrentUserDocument, options);
}
export function useCurrentUserLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>(CurrentUserDocument, options);
}
export type CurrentUserQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>;