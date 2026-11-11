// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Runtime discriminators between the native @vue/apollo-composable v5 result
// shapes and the compat (v4-style) ones: each probes a member that only the
// native shape carries.

import type {
  MutationOperationReturn,
  QueryOperationReturn,
  SubscriptionOperationReturn,
} from '#shared/types/server/apollo/handler.ts'

import type { OperationVariables } from '@apollo/client'
import type { useLazyQuery, useMutation, useQuery, useSubscription } from '@vue/apollo-composable'

export const isNativeQueryResult = <TResult, TVariables extends OperationVariables>(
  result: QueryOperationReturn<TResult, TVariables>,
): result is useQuery.Result<TResult, TVariables> | useLazyQuery.Result<TResult, TVariables> =>
  'current' in result

export const isNativeMutationResult = <TResult, TVariables extends OperationVariables>(
  result: MutationOperationReturn<TResult, TVariables>,
): result is useMutation.Result<TResult, TVariables> => 'reset' in result

export const isNativeSubscriptionResult = <TResult, TVariables extends OperationVariables>(
  result: SubscriptionOperationReturn<TResult, TVariables>,
): result is useSubscription.Result<TResult, TVariables> => 'onComplete' in result
