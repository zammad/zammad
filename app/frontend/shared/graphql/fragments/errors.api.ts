import * as Types from '../types';

import gql from 'graphql-tag';
export const ErrorsFragmentDoc = gql`
    fragment errors on UserError {
  message
  field
}
    `;