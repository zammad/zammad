import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const UserTaskbarTabAttributesFragmentDoc = gql`
    fragment userTaskbarTabAttributes on User {
  id
  fullname
  active
}
    `;