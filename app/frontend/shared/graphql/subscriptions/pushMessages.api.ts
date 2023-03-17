import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const PushMessagesDocument = gql`
    subscription pushMessages {
  pushMessages {
    title
    text
  }
}
    `;
export function usePushMessagesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables>(PushMessagesDocument, {}, options);
}
export type PushMessagesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.PushMessagesSubscription, Types.PushMessagesSubscriptionVariables>;