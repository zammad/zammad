import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChannelEmailAddDocument = gql`
    mutation channelEmailAdd($input: ChannelEmailAddInput!) {
  channelEmailAdd(input: $input) {
    channel {
      options
      group {
        id
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailAddMutation(options: VueApolloComposable.useMutation.Options<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables>(ChannelEmailAddDocument, options);
}
export type ChannelEmailAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables>;