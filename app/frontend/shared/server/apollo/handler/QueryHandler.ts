// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-use-before-define */

import type { Ref, WatchStopHandle } from 'vue'
import { watch } from 'vue'
import type {
  ApolloQueryResult,
  FetchMoreOptions,
  FetchMoreQueryOptions,
  OperationVariables,
  SubscribeToMoreOptions,
} from '@apollo/client/core'
import type {
  OperationQueryOptionsReturn,
  OperationQueryResult,
  WatchResultCallback,
} from '@shared/types/server/apollo/handler'
import type { ReactiveFunction } from '@shared/types/utils'
import type { UseQueryOptions, UseQueryReturn } from '@vue/apollo-composable'
import BaseHandler from './BaseHandler'

export default class QueryHandler<
  TResult = OperationQueryResult,
  TVariables = OperationVariables,
> extends BaseHandler<
  TResult,
  TVariables,
  UseQueryReturn<TResult, TVariables>
> {
  private firstResultLoaded = false

  public async trigger(variables?: TVariables) {
    this.load(variables)
    // load triggers "forceDisable", which triggers a watcher,
    // so we need to wait for the query to be created before we can refetch
    // we can't use nextTick, because queries variables are not updated yet
    // and it will call the server with the first variables and the new ones
    await new Promise((r) => setTimeout(r, 0))
    const query = this.operationResult.query.value
    if (!query) return null
    // this will take result from cache, respecting variables
    // if it's not in cache, it will fetch result from server
    const result = await query.result()
    return result.data
  }

  public options(): OperationQueryOptionsReturn<TResult, TVariables> {
    return this.operationResult.options
  }

  public result(): Ref<TResult | undefined> {
    return this.operationResult.result
  }

  public subscribeToMore<
    TSubscriptionVariables = TVariables,
    TSubscriptionData = TResult,
  >(
    options:
      | SubscribeToMoreOptions<
          TResult,
          TSubscriptionVariables,
          TSubscriptionData
        >
      | ReactiveFunction<
          SubscribeToMoreOptions<
            TResult,
            TSubscriptionVariables,
            TSubscriptionData
          >
        >,
  ): void {
    return this.operationResult.subscribeToMore(options)
  }

  public fetchMore(
    options: FetchMoreQueryOptions<TVariables, TResult> &
      FetchMoreOptions<TResult, TVariables>,
  ): Promise<Maybe<TResult>> {
    return new Promise((resolve, reject) => {
      const fetchMore = this.operationResult.fetchMore(options)

      if (!fetchMore) {
        resolve(null)
        return
      }

      fetchMore
        .then((result) => {
          resolve(result.data)
        })
        .catch(() => {
          reject(this.operationError().value)
        })
    })
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

  public load(
    variables?: TVariables,
    options?: UseQueryOptions<TResult, TVariables>,
  ): void {
    const operation = this.operationResult as unknown as {
      load?: (
        document?: unknown,
        variables?: TVariables,
        options?: UseQueryOptions<TResult, TVariables>,
      ) => void
    }

    if (typeof operation.load !== 'function') {
      return
    }

    operation.load(undefined, variables, options)
  }

  public start(): void {
    this.operationResult.start()
  }

  public stop(): void {
    this.firstResultLoaded = false
    this.operationResult.stop()
  }

  public abort() {
    this.operationResult.stop()
    this.operationResult.start()
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

  public watchOnceOnResult(callback: WatchResultCallback<TResult>) {
    const watchStopHandle = watch(
      this.result(),
      (result) => {
        if (!result) {
          return
        }
        callback(result)
        watchStopHandle()
      },
      {
        // Needed for when the component is mounted after the first mount, in this case
        // result will already contain the data and the watch will otherwise not be triggered.
        immediate: true,
      },
    )
  }

  public watchOnResult(
    callback: WatchResultCallback<TResult>,
  ): WatchStopHandle {
    return watch(
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

  public onResult(
    callback: (result: ApolloQueryResult<TResult>) => void,
  ): void {
    this.operationResult.onResult(callback)
  }
}
