import * as Types from '../types';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from './userAttributes.api';
export const CurrentUserAttributesFragmentDoc = gql`
    fragment currentUserAttributes on User {
  ...userAttributes
  email
  permissions {
    names
  }
}
    ${UserAttributesFragmentDoc}`;