import * as Types from '../types';

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