import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const PushMessagesDocument = gql`
    subscription pushMessages {
  pushMessages {
    title
    text
  }
}
    `;
export function usePushMessagesSubscription(options: VueApolloComposable.useSubscription.Options<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables>(PushMessagesDocument, options);
}
export type PushMessagesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables>;