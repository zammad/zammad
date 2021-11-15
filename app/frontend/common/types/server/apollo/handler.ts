// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import {
  UseMutationReturn,
  UseQueryReturn,
  UseQueryOptions,
} from '@vue/apollo-composable'
import { Ref } from 'vue'
import { GraphQLHandlerError } from '@common/types/error'

export type OperationReturn<TResult, TVariables> =
  | UseQueryReturn<TResult, TVariables>
  | UseMutationReturn<TResult, TVariables>

export type OperationQueryOptionsReturn<TResult, TVariables> =
  | UseQueryOptions<TResult, TVariables>
  | Ref<UseQueryOptions<TResult, TVariables>>

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
  errorCallback?: (error: GraphQLHandlerError) => void
}

export type CommonHandlerOptions<TOptions> = BaseHandlerOptions & TOptions

export type CommonHandlerOptionsParameter<TOptions> =
  Partial<BaseHandlerOptions> & Partial<TOptions>
