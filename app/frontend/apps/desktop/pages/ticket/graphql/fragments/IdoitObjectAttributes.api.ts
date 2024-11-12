import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const IdoitObjectAttributesFragmentDoc = gql`
    fragment IdoitObjectAttributes on TicketExternalReferencesIdoitObject {
  idoitObjectId
  link
  title
  type
  status
}
    `;