// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import {
  UseMutationReturn,
  UseQueryReturn,
  UseQueryOptions,
  UseMutationOptions,
} from '@vue/apollo-composable'
import { Ref } from 'vue'
import { ReactiveFunction } from '@common/types/utils'
import { LogLevel } from '@common/types/utils/log'

export type OperationReturn<TResult, TVariables> =
  | UseQueryReturn<TResult, TVariables>
  | UseMutationReturn<TResult, TVariables>

export type OperationQueryOptions<TResult, TVariables> =
  | UseQueryOptions<TResult, TVariables>
  | Ref<UseQueryOptions<TResult, TVariables>>
  | ReactiveFunction<UseQueryOptions<TResult, TVariables>>

export type OperationMutationOptions<TResult, TVariables> =
  | UseMutationOptions<TResult, TVariables>
  | ReactiveFunction<UseMutationOptions<TResult, TVariables>>

export type OperationMutationOptionsWithoutVariables<TResult, TVariables> =
  Omit<OperationMutationOptions<TResult, TVariables>, 'variables'>

export type OperationOptions<TResult, TVariables> =
  | OperationQueryOptions<TResult, TVariables>
  | OperationMutationOptions<TResult, TVariables>

export type OperationQueryOptionsReturn<TResult, TVariables> =
  | UseQueryOptions<TResult, TVariables>
  | Ref<UseQueryOptions<TResult, TVariables>>

export type OperationQueryVariablesParameter<TVariables> =
  | TVariables
  | Ref<TVariables>
  | ReactiveFunction<TVariables>

export type OperationMutationVariablesParameter<TVariables> = TVariables &
  ReactiveFunction<TVariables>

export type OperationVariablesParameter<TVariables> =
  | OperationQueryVariablesParameter<TVariables>
  | OperationMutationVariablesParameter<TVariables>

export type OperationQueryFunction<TResult, TVariables> = (
  ...args: [
    (
      | OperationQueryVariablesParameter<TVariables>
      | (OperationQueryOptions<TResult, TVariables> | undefined)
    ),
    OperationQueryOptions<TResult, TVariables>?,
  ]
) => UseQueryReturn<TResult, TVariables>

export type OperationMutationFunction<TResult, TVariables> =
  | ((
      options: OperationMutationOptions<TResult, TVariables>,
    ) => UseMutationReturn<TResult, TVariables>)
  | ((
      options?: OperationMutationOptions<TResult, TVariables>,
    ) => UseMutationReturn<TResult, TVariables>)

export type OperationFunction<TResult, TVariables> =
  | OperationQueryFunction<TResult, TVariables>
  | OperationMutationFunction<TResult, TVariables>

export type OperationQueryResult = {
  __typename?: 'Queries'
  [key: string]: unknown
}

export type OperationMutationResult = {
  __typename?: 'Mutations'
  [key: string]: unknown
}

export type OperationResult = OperationQueryResult | OperationMutationResult

export interface BaseHandlerOptions {
  errorShowNotification: boolean
  errorNotitifactionMessage: string
  errorNotitifactionType: string
  errorLogLevel: LogLevel
}

export type MutationHandlerOptions = {
  directSendMutation: boolean
}

export type CommonHandlerOptions<TOptions> = BaseHandlerOptions & TOptions

export type CommonHandlerOptionsParameter<TOptions> =
  Partial<BaseHandlerOptions> & Partial<TOptions>
