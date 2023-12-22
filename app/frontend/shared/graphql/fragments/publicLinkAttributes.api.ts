import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const PublicLinkAttributesFragmentDoc = gql`
    fragment publicLinkAttributes on PublicLink {
  id
  link
  title
  description
  newTab
}
    `;