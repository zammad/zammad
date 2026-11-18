import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const IdoitUpObjectAttributesFragmentDoc = gql`
    fragment IdoitUpObjectAttributes on TicketExternalReferencesIdoitUpObject {
  idoitUpObjectId
  link
  title
  type
  status
}
    `;