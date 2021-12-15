// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { OperationVariables, SubscribeToMoreOptions } from '@apollo/client/core'
import BaseHandler from '@common/server/apollo/handler/BaseHandler'
import {
  OperationQueryOptionsReturn,
  OperationQueryResult,
  WatchResultCallback,
} from '@common/types/server/apollo/handler'
import { ReactiveFunction } from '@common/types/utils'
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
  private firstResultLoaded = false

  public options(): OperationQueryOptionsReturn<TResult, TVariables> {
    return this.operationResult.options
  }

  public result(): Ref<TResult | undefined> {
    return this.operationResult.result
  }

  public subscribeToMore<TSubscriptionData = TResult>(
    options: ReactiveFunction<
      SubscribeToMoreOptions<TResult, TVariables, TSubscriptionData>
    >,
  ): void {
    return this.operationResult.subscribeToMore(options)
  }

  public refetch(variables?: TVariables): Promise<Maybe<TResult>> {
    return new Promise((resolve, reject) => {
      const refetch = this.operationResult.refetch(variables)

      if (!refetch) {
        resolve(null)
        return
      }

      refetch
        .then((result) => {
          resolve(result.data)
        })
        .catch(() => {
          reject(this.operationError().value)
        })
    })
  }

  public async onLoaded(
    triggerPossibleRefetch = false,
  ): Promise<Maybe<TResult>> {
    if (this.firstResultLoaded && triggerPossibleRefetch) {
      return this.refetch()
    }

    return new Promise((resolve, reject) => {
      let errorUnsubscribe!: () => void
      let resultUnsubscribe!: () => void

      const onFirstResultLoaded = () => {
        this.firstResultLoaded = true
        resultUnsubscribe()
        errorUnsubscribe()
      }

      resultUnsubscribe = watch(this.result(), (result) => {
        // After a variable change, the result will be reseted.
        if (result === undefined) return null

        // Remove the watchers again after the promise was resolved.
        onFirstResultLoaded()
        return resolve(result || null)
      })

      errorUnsubscribe = watch(this.operationError(), (error) => {
        onFirstResultLoaded()
        return reject(error)
      })
    })
  }

  public loadedResult(triggerPossibleRefetch = false): Promise<Maybe<TResult>> {
    return this.onLoaded(triggerPossibleRefetch)
      .then((data: Maybe<TResult>) => data)
      .catch((error) => error)
  }

  public watchOnResult(callback: WatchResultCallback<TResult>): void {
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
