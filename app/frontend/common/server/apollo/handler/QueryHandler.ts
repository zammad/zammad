// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import {
  OperationVariables,
  NetworkStatus,
  ApolloQueryResult,
} from '@apollo/client/core'
import BaseHandler from '@common/server/apollo/handler/BaseHandler'
import {
  OperationQueryOptionsReturn,
  OperationQueryResult,
} from '@common/types/server/apollo/handler'
import { UseQueryReturn } from '@vue/apollo-composable'
import { Ref, watch } from 'vue'

export default class QueryHandler<
  TResult = OperationQueryResult,
  TVariables = OperationVariables,
> extends BaseHandler<
  TResult,
  TVariables,
  UseQueryReturn<TResult, TVariables>
> {
  private refetchTriggered?: boolean

  private refetchResolver?: (result?: ApolloQueryResult<TResult>) => void

  public options(): OperationQueryOptionsReturn<TResult, TVariables> {
    return this.operationResult.options
  }

  public result(): Ref<TResult | undefined> {
    return this.operationResult.result
  }

  public refetch(variables?: TVariables): Promise<Maybe<TResult>> {
    this.refetchTriggered = true

    return new Promise((resolve, reject) => {
      const refetch = this.operationResult.refetch(variables)

      if (!refetch) {
        resolve(null)
        return
      }

      refetch
        .then((result) => {
          if (this.refetchResolver) this.refetchResolver(result)
          this.refetchTriggered = false

          resolve(result.data)
        })
        .catch(() => {
          if (this.refetchResolver) this.refetchResolver()
          this.refetchTriggered = false

          reject()
        })
    })
  }

  public async onLoaded(): Promise<Maybe<TResult>> {
    return new Promise((resolve, reject) => {
      if (this.refetchTriggered) {
        this.refetchResolver = (result) => {
          if (!result) {
            return reject(this.operationError().value)
          }
          return resolve(result?.data || null)
        }
      } else {
        this.operationResult.onResult((result) => {
          if (result.networkStatus === NetworkStatus.error) {
            return reject(this.operationError().value)
          }

          return resolve(result.data)
        })
      }
    })
  }

  public loadedResult(): Promise<Maybe<TResult>> {
    return this.onLoaded()
      .then((data: Maybe<TResult>) => data)
      .catch((error) => error)
  }

  public watchOnResult(callback: (result?: TResult) => void): void {
    watch(
      this.result(),
      (result) => {
        if (!result) {
          return
        }
        callback(result)
      },
      {
        // Needed for when the component is mounted after the first mount, in this case
        // result will already contain the data and the watch will otherwise not be triggered.
        immediate: true,
      },
    )
  }
}
