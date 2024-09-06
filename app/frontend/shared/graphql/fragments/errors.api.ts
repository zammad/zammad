import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ErrorsFragmentDoc = gql`
    fragment errors on UserError {
  message
  field
  exception
}
    `;