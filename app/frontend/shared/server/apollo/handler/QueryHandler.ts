// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-use-before-define */

import { getOperationName } from '@apollo/client/utilities'
import { useApolloClient } from '@vue/apollo-composable'
import { watch, nextTick } from 'vue'

import type {
  OperationQueryOptionsReturn,
  OperationQueryResult,
  WatchResultCallback,
} from '#shared/types/server/apollo/handler.ts'
import type { ReactiveFunction } from '#shared/types/utils.ts'

import BaseHandler from './BaseHandler.ts'

import type {
  ApolloError,
  ApolloQueryResult,
  FetchMoreOptions,
  FetchMoreQueryOptions,
  ObservableQuery,
  OperationVariables,
  QueryOptions,
  SubscribeToMoreOptions,
} from '@apollo/client/core'
import type { UseQueryOptions, UseQueryReturn } from '@vue/apollo-composable'
import type { Ref, WatchStopHandle } from 'vue'

export default class QueryHandler<
  TResult = OperationQueryResult,
  TVariables extends OperationVariables = OperationVariables,
> extends BaseHandler<
  TResult,
  TVariables,
  UseQueryReturn<TResult, TVariables>
> {
  private lastCancel: (() => void) | null = null

  public cancel() {
    this.lastCancel?.()
  }

  /**
   * Calls the query immidiately and returns the result in `data` property.
   *
   * Will throw an error, if used with "useQuery" instead of "useLazyQuery".
   *
   * Returns cached result, if there is one. Otherwise, will
   * `fetch` the result from the server.
   *
   * If called multiple times, cancels the previous query.
   *
   * Respects options that were defined in `useLazyQuery`, but can be overriden.
   *
   * If an error was throws, `data` is `null`, and `error` is the thrown error.
   */
  public async query(
    options: Omit<QueryOptions<TVariables, TResult>, 'query'> = {},
  ) {
    const {
      options: defaultOptions,
      document: { value: node },
    } = this.operationResult
    if (import.meta.env.DEV && !node) {
      throw new Error(`No query document available.`)
    }
    if (import.meta.env.DEV && !('load' in this.operationResult)) {
      let error = `${getOperationName(
        node!,
      )} is initialized with "useQuery" instead of "useLazyQuery". `
      error += `If you need to get the value immediately with ".query()", use "useLazyQuery" instead to not start extra network requests. `
      error += `"useQuery" should be used inside components to dynamically react to changed data.`
      throw new Error(error)
    }
    this.cancel()
    const { client } = useApolloClient()
    const aborter =
      typeof AbortController !== 'undefined' ? new AbortController() : null
    this.lastCancel = () => aborter?.abort()
    const { fetchPolicy: defaultFetchPolicy, ...defaultOptionsValue } =
      'value' in defaultOptions ? defaultOptions.value : defaultOptions
    const fetchPolicy =
      options.fetchPolicy ||
      (defaultFetchPolicy !== 'cache-and-network'
        ? defaultFetchPolicy
        : undefined)
    try {
      return await client.query<TResult, TVariables>({
        ...defaultOptionsValue,
        ...options,
        fetchPolicy,
        query: node!,
        context: {
          ...defaultOptionsValue.context,
          ...options.context,
          fetchOptions: {
            signal: aborter?.signal,
          },
        },
      })
    } catch (error) {
      // TODO: do we need to handleError here also in a genric way?

      return {
        data: null,
        error: error as ApolloError,
      }
    } finally {
      this.lastCancel = null
    }
  }

  public options(): OperationQueryOptionsReturn<TResult, TVariables> {
    return this.operationResult.options
  }

  public result(): Ref<TResult | undefined> {
    return this.operationResult.result
  }

  public watchQuery(): Ref<
    ObservableQuery<TResult, TVariables> | null | undefined
  > {
    return this.operationResult.query
  }

  public subscribeToMore<
    TSubscriptionVariables extends OperationVariables = TVariables,
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

  public refetch(
    variables?: Partial<TVariables>,
  ): Promise<{ data: Maybe<TResult>; error?: unknown }> {
    return new Promise((resolve, reject) => {
      const refetch = this.operationResult.refetch(variables as TVariables)

      if (!refetch) {
        resolve({ data: null })
        return
      }

      refetch
        .then((result) => {
          resolve({ data: result.data })
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
      ) => false | Promise<TResult>
    }

    if (typeof operation.load !== 'function') {
      return
    }

    const result = operation.load(undefined, variables, options)
    if (result instanceof Promise) {
      // error is handled in BaseHandler
      result.catch(() => {})
    }
  }

  public isFirstRun(): boolean {
    return this.operationResult.forceDisabled.value
  }

  public start(): void {
    this.operationResult.start()
  }

  public stop(): void {
    this.operationResult.stop()
  }

  public abort() {
    this.operationResult.stop()
    this.operationResult.start()
  }

  public watchOnceOnResult(callback: WatchResultCallback<TResult>) {
    let watchStopHandle: WatchStopHandle | null = null

    watchStopHandle = watch(
      this.result(),
      (result) => {
        if (!watchStopHandle || !result) {
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
    callback: (result: ApolloQueryResult<TResult | undefined>) => void,
    ignoreFirstResult?: boolean,
  ): void {
    if (ignoreFirstResult) {
      this.watchOnceOnResult(() => {
        nextTick(() => {
          this.operationResult.onResult(callback)
        })
      })

      return
    }

    this.operationResult.onResult(callback)
  }
}
