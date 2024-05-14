import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from './userAttributes.api';
export const CurrentUserAttributesFragmentDoc = gql`
    fragment currentUserAttributes on User {
  ...userAttributes
  authorizations {
    id
    provider
    uid
    username
  }
  email
  permissions {
    names
  }
}
    ${UserAttributesFragmentDoc}`;