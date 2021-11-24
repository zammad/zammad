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