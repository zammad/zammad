import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserPersonalSettingsFragmentDoc } from './userPersonalSettings.api';
import { ObjectAttributeValuesFragmentDoc } from './objectAttributeValues.api';
export const UserAttributesFragmentDoc = gql`
    fragment userAttributes on User {
  id
  internalId
  firstname
  lastname
  fullname
  image
  outOfOffice
  outOfOfficeStartAt
  outOfOfficeEndAt
  outOfOfficeReplacement {
    id
    internalId
    firstname
    lastname
    fullname
    login
    phone
    email
  }
  preferences
  ...userPersonalSettings
  objectAttributeValues {
    ...objectAttributeValues
  }
  organization {
    id
    internalId
    name
    active
    objectAttributeValues {
      ...objectAttributeValues
    }
  }
  hasSecondaryOrganizations
}
    ${UserPersonalSettingsFragmentDoc}
${ObjectAttributeValuesFragmentDoc}`;