// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { NotificationTypes } from '#shared/components/CommonNotifications/index.ts'
import type { PageInfo } from '#shared/graphql/types.ts'
import type { ReactiveFunction } from '#shared/types/utils.ts'

import type { GraphQLHandlerError } from '../../error.ts'
import type {
  DefaultContext,
  ErrorLike,
  OperationVariables,
  TypedDocumentNode,
} from '@apollo/client'
import type { useLazyQuery, useMutation, useQuery, useSubscription } from '@vue/apollo-composable'
import type {
  UseLazyQueryReturn,
  UseMutationReturn,
  UseQueryReturn,
  UseQueryOptions,
  UseSubscriptionReturn,
  UseSubscriptionOptions,
  UseMutationOptions,
} from '@vue/apollo-composable/compat'
import type { DocumentNode } from 'graphql'
import type { Ref } from 'vue'

// Until every document is migrated (and the compat entry removed with it), a
// handler accepts the compat (v4-style) and the native v5 composable result of
// its operation kind alike.
export type QueryOperationReturn<TResult, TVariables extends OperationVariables> =
  | UseQueryReturn<TResult, TVariables>
  | UseLazyQueryReturn<TResult, TVariables>
  | useQuery.Result<TResult, TVariables>
  | useLazyQuery.Result<TResult, TVariables>

export type MutationOperationReturn<TResult, TVariables extends OperationVariables> =
  | UseMutationReturn<TResult, TVariables>
  | useMutation.Result<TResult, TVariables>

export type SubscriptionOperationReturn<TResult, TVariables extends OperationVariables> =
  | UseSubscriptionReturn<TResult, TVariables>
  | useSubscription.Result<TResult, TVariables>

export type OperationReturn<TResult, TVariables extends OperationVariables> =
  | QueryOperationReturn<TResult, TVariables>
  | MutationOperationReturn<TResult, TVariables>
  | SubscriptionOperationReturn<TResult, TVariables>

export type OperationQueryOptionsReturn<TResult, TVariables extends OperationVariables> = Readonly<
  Ref<UseQueryOptions<TResult, TVariables> | useQuery.Options<TResult, TVariables> | undefined>
>

export type OperationSubscriptionOptionsReturn<
  TResult,
  TVariables extends OperationVariables,
> = Readonly<
  Ref<
    | UseSubscriptionOptions<TResult, TVariables>
    | useSubscription.Options<TResult, TVariables>
    | undefined
  >
>

export interface SubscribeToMoreUpdateQueryOptions<
  TResult,
  TSubscriptionVariables extends OperationVariables,
  TSubscriptionData,
> {
  subscriptionData: { data: TSubscriptionData }
  variables?: TSubscriptionVariables
  // The previous result is only complete when the cache holds every field of the query, and
  //   `null` while it holds nothing for it yet.
  previousData?: TResult | null
  complete?: boolean
}

export interface SubscribeToMoreOptions<
  TResult,
  TSubscriptionVariables extends OperationVariables,
  TSubscriptionData,
> {
  document: DocumentNode | TypedDocumentNode<TSubscriptionData, TSubscriptionVariables>
  variables?: TSubscriptionVariables
  // Returning `null` or `undefined` leaves the query result untouched.
  updateQuery?: (
    previousResult: TResult | null,
    options: SubscribeToMoreUpdateQueryOptions<TResult, TSubscriptionVariables, TSubscriptionData>,
  ) => TResult | null | undefined
  onError?: (error: ErrorLike) => void
  context?: DefaultContext
}

export type OperationSubscriptionsResult = {
  __typename?: 'Subscriptions'
  [key: string]: unknown
}

export type OperationQueryResult = {
  __typename?: 'Queries'
  [key: string]: unknown
}

export type OperationMutationResult = {
  __typename?: 'Mutations'
  [key: string]: unknown
}

export type OperationMutationOptions<TResult, TVariables> =
  | UseMutationOptions<TResult, TVariables>
  | ReactiveFunction<UseMutationOptions<TResult, TVariables>>

export type OperationMutationFunction<
  // oxlint-disable-next-line no-explicit-any
  TResult = any,
  // oxlint-disable-next-line no-explicit-any
  TVariables extends OperationVariables = any,
> = (
  options?: OperationMutationOptions<TResult, TVariables>,
) => MutationOperationReturn<TResult, TVariables>

export type OperationQueryFunction<
  TResult = OperationQueryResult,
  TVariables extends OperationVariables = OperationVariables,
> = (options: OperationVariables) => QueryOperationReturn<TResult, TVariables>

export type BaseConnection = {
  __typename?: string
  pageInfo: PageInfo
  nodes?: Maybe<Array<Maybe<unknown>>>
  edges?: Maybe<Array<Maybe<unknown>>>
  totalCount: number
}

export type PaginationVariables = {
  cursor?: Maybe<string>
  pageSize?: Maybe<number>
}

export type OperationResult =
  | OperationQueryResult
  | OperationMutationResult
  | OperationSubscriptionsResult

export interface BaseHandlerOptions {
  errorShowNotification: boolean
  // Authentication errors are silenced by default, because they usually only
  //  mean that the session is gone and the user ends up on the login screen
  //  anyway. Operations for which an authentication error is an actual result -
  //  the login itself - have to opt in to see it.
  errorShowNotificationOnNotAuthorized: boolean
  errorNotificationMessage: string
  errorNotificationType: NotificationTypes
  errorCallback?: (error: GraphQLHandlerError) => void | boolean
}

export interface QueryHandlerOptions {
  triggerRefetchOnConnectionReconnect: boolean | (() => boolean)
}

export type CommonHandlerOptions<TOptions> = BaseHandlerOptions & TOptions

export type CommonHandlerOptionsParameter<TOptions> = Partial<BaseHandlerOptions> &
  Partial<TOptions>

export type WatchResultCallback<TResult> = (result: TResult) => void
