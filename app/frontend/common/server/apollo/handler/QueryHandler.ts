// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { OperationVariables, NetworkStatus } from '@apollo/client/core'
import BaseHandler from '@common/server/apollo/handler/BaseHandler'
import {
  OperationQueryFunction,
  OperationQueryOptions,
  OperationQueryOptionsReturn,
  OperationQueryResult,
  OperationQueryVariablesParameter,
} from '@common/types/server/apollo/handler'
import { UseQueryReturn } from '@vue/apollo-composable'
import { Ref } from 'vue'

export default class QueryHandler<
  TResult = OperationQueryResult,
  TVariables = OperationVariables,
> extends BaseHandler<
  TResult,
  TVariables,
  UseQueryReturn<TResult, TVariables>,
  OperationQueryFunction<TResult, TVariables>,
  OperationQueryOptions<TResult, TVariables>
> {
  public operationExecute(
    variables?: OperationQueryVariablesParameter<TVariables>,
    options?: OperationQueryOptions<TResult, TVariables>,
  ): UseQueryReturn<TResult, TVariables> {
    if (variables) return this.operation(variables, options)

    return this.operation(options)
  }

  public options(): OperationQueryOptionsReturn<TResult, TVariables> {
    return this.operationResult.options
  }

  public result(): Ref<TResult | undefined> {
    return this.operationResult.result
  }

  public async onLoaded(): Promise<Maybe<TResult>> {
    return new Promise((resolve, reject) => {
      this.operationResult.onResult((result) => {
        if (result.networkStatus === NetworkStatus.error) {
          return reject(this.operationError())
        }

        return resolve(result.data)
      })
    })
  }
}
