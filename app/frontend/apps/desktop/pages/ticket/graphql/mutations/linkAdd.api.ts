import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LinkAddDocument = gql`
    mutation linkAdd($input: LinkInput!) {
  linkAdd(input: $input) {
    link {
      type
      item {
        ... on Ticket {
          id
          internalId
          title
          state {
            id
            name
          }
          stateColorCode
        }
        ... on KnowledgeBaseAnswerTranslation {
          id
        }
      }
    }
    errors {
      message
      field
    }
  }
}
    `;
export function useLinkAddMutation(options: VueApolloComposable.UseMutationOptions<Types.LinkAddMutation, Types.LinkAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.LinkAddMutation, Types.LinkAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.LinkAddMutation, Types.LinkAddMutationVariables>(LinkAddDocument, options);
}
export type LinkAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.LinkAddMutation, Types.LinkAddMutationVariables>;