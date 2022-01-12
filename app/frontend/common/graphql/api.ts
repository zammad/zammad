import * as Types from './types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;
export const ObjectAttributeValuesFragmentDoc = gql`
    fragment objectAttributeValues on ObjectAttributeValue {
  attribute {
    name
    display
    dataType
    dataOption
    screens
    editable
    active
  }
  value
}
    `;
export const LoginDocument = gql`
    mutation login($login: String!, $password: String!, $fingerprint: String!) {
  login(login: $login, password: $password, fingerprint: $fingerprint) {
    sessionId
  }
}
    `;

/**
 * __useLoginMutation__
 *
 * To run a mutation, you first call `useLoginMutation` within a Vue component and pass it any options that fit your needs.
 * When your component renders, `useLoginMutation` returns an object that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - Several other properties: https://v4.apollo.vuejs.org/api/use-mutation.html#return
 *
 * @param options that will be passed into the mutation, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/mutation.html#options;
 *
 * @example
 * const { mutate, loading, error, onDone } = useLoginMutation({
 *   variables: {
 *     login: // value for 'login'
 *     password: // value for 'password'
 *     fingerprint: // value for 'fingerprint'
 *   },
 * });
 */
export function useLoginMutation(options: VueApolloComposable.UseMutationOptions<Types.LoginMutation, Types.LoginMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.LoginMutation, Types.LoginMutationVariables>>) {
  return VueApolloComposable.useMutation<Types.LoginMutation, Types.LoginMutationVariables>(LoginDocument, options);
}
export type LoginMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.LoginMutation, Types.LoginMutationVariables>;
export const LogoutDocument = gql`
    mutation logout {
  logout {
    success
  }
}
    `;

/**
 * __useLogoutMutation__
 *
 * To run a mutation, you first call `useLogoutMutation` within a Vue component and pass it any options that fit your needs.
 * When your component renders, `useLogoutMutation` returns an object that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - Several other properties: https://v4.apollo.vuejs.org/api/use-mutation.html#return
 *
 * @param options that will be passed into the mutation, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/mutation.html#options;
 *
 * @example
 * const { mutate, loading, error, onDone } = useLogoutMutation();
 */
export function useLogoutMutation(options: VueApolloComposable.UseMutationOptions<Types.LogoutMutation, Types.LogoutMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.LogoutMutation, Types.LogoutMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.LogoutMutation, Types.LogoutMutationVariables>(LogoutDocument, options);
}
export type LogoutMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.LogoutMutation, Types.LogoutMutationVariables>;
export const ApplicationConfigDocument = gql`
    query applicationConfig {
  applicationConfig {
    key
    value
  }
}
    `;

/**
 * __useApplicationConfigQuery__
 *
 * To run a query within a Vue component, call `useApplicationConfigQuery` and pass it any options that fit your needs.
 * When your component renders, `useApplicationConfigQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useApplicationConfigQuery();
 */
export function useApplicationConfigQuery(options: VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>(ApplicationConfigDocument, {}, options);
}
export type ApplicationConfigQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>;
export const CurrentUserDocument = gql`
    query currentUser {
  currentUser {
    firstname
    lastname
    preferences
    objectAttributeValues {
      ...objectAttributeValues
    }
    organization {
      name
      objectAttributeValues {
        ...objectAttributeValues
      }
    }
    permissions {
      names
    }
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;

/**
 * __useCurrentUserQuery__
 *
 * To run a query within a Vue component, call `useCurrentUserQuery` and pass it any options that fit your needs.
 * When your component renders, `useCurrentUserQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useCurrentUserQuery();
 */
export function useCurrentUserQuery(options: VueApolloComposable.UseQueryOptions<Types.CurrentUserQuery, Types.CurrentUserQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>(CurrentUserDocument, {}, options);
}
export type CurrentUserQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>;
export const LocalesDocument = gql`
    query locales {
  locales {
    locale
    alias
    name
    dir
    active
  }
}
    `;

/**
 * __useLocalesQuery__
 *
 * To run a query within a Vue component, call `useLocalesQuery` and pass it any options that fit your needs.
 * When your component renders, `useLocalesQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useLocalesQuery();
 */
export function useLocalesQuery(options: VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.LocalesQuery, Types.LocalesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.LocalesQuery, Types.LocalesQueryVariables>(LocalesDocument, {}, options);
}
export type LocalesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.LocalesQuery, Types.LocalesQueryVariables>;
export const OverviewsDocument = gql`
    query overviews($withTicketCount: Boolean!) {
  overviews {
    edges {
      node {
        id
        name
        link
        prio
        order
        view
        active
        ticketCount @include(if: $withTicketCount)
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    `;

/**
 * __useOverviewsQuery__
 *
 * To run a query within a Vue component, call `useOverviewsQuery` and pass it any options that fit your needs.
 * When your component renders, `useOverviewsQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param variables that will be passed into the query
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useOverviewsQuery({
 *   withTicketCount: // value for 'withTicketCount'
 * });
 */
export function useOverviewsQuery(variables: Types.OverviewsQueryVariables | VueCompositionApi.Ref<Types.OverviewsQueryVariables> | ReactiveFunction<Types.OverviewsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OverviewsQuery, Types.OverviewsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OverviewsQuery, Types.OverviewsQueryVariables>(OverviewsDocument, variables, options);
}
export type OverviewsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OverviewsQuery, Types.OverviewsQueryVariables>;
export const SessionIdDocument = gql`
    query sessionId {
  sessionId
}
    `;

/**
 * __useSessionIdQuery__
 *
 * To run a query within a Vue component, call `useSessionIdQuery` and pass it any options that fit your needs.
 * When your component renders, `useSessionIdQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useSessionIdQuery();
 */
export function useSessionIdQuery(options: VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.SessionIdQuery, Types.SessionIdQueryVariables>(SessionIdDocument, {}, options);
}
export type SessionIdQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SessionIdQuery, Types.SessionIdQueryVariables>;
export const TranslationsDocument = gql`
    query translations($locale: String!, $cacheKey: String) {
  translations(locale: $locale, cacheKey: $cacheKey) {
    isCacheStillValid
    cacheKey
    translations
  }
}
    `;

/**
 * __useTranslationsQuery__
 *
 * To run a query within a Vue component, call `useTranslationsQuery` and pass it any options that fit your needs.
 * When your component renders, `useTranslationsQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param variables that will be passed into the query
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useTranslationsQuery({
 *   locale: // value for 'locale'
 *   cacheKey: // value for 'cacheKey'
 * });
 */
export function useTranslationsQuery(variables: Types.TranslationsQueryVariables | VueCompositionApi.Ref<Types.TranslationsQueryVariables> | ReactiveFunction<Types.TranslationsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TranslationsQuery, Types.TranslationsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TranslationsQuery, Types.TranslationsQueryVariables>(TranslationsDocument, variables, options);
}
export type TranslationsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TranslationsQuery, Types.TranslationsQueryVariables>;
export const ConfigUpdatedDocument = gql`
    subscription configUpdated {
  configUpdated {
    setting {
      key
      value
    }
  }
}
    `;

/**
 * __useConfigUpdatedSubscription__
 *
 * To run a query within a Vue component, call `useConfigUpdatedSubscription` and pass it any options that fit your needs.
 * When your component renders, `useConfigUpdatedSubscription` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param options that will be passed into the subscription, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/subscription.html#options;
 *
 * @example
 * const { result, loading, error } = useConfigUpdatedSubscription();
 */
export function useConfigUpdatedSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.ConfigUpdatedSubscription, Types.ConfigUpdatedSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.ConfigUpdatedSubscription, Types.ConfigUpdatedSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.ConfigUpdatedSubscription, Types.ConfigUpdatedSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.ConfigUpdatedSubscription, Types.ConfigUpdatedSubscriptionVariables>(ConfigUpdatedDocument, {}, options);
}
export type ConfigUpdatedSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.ConfigUpdatedSubscription, Types.ConfigUpdatedSubscriptionVariables>;