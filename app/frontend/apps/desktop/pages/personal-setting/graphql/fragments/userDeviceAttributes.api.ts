import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const UserDeviceAttributesFragmentDoc = gql`
    fragment userDeviceAttributes on UserDevice {
  id
  userId
  name
  os
  browser
  location
  deviceDetails
  locationDetails
  fingerprint
  userAgent
  ip
  createdAt
  updatedAt
}
    `;