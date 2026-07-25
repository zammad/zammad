import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const SnipeitAssetAttributesFragmentDoc = gql`
    fragment SnipeitAssetAttributes on TicketExternalReferencesSnipeitAsset {
  snipeitAssetId
  link
  name
  assetTag
  serial
  model
  status
  category
  location
}
    `;