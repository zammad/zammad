// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { toErrorLike } from '@apollo/client/errors'
import { useApolloClient } from '@vue/apollo-composable/compat'
import { getOperationAST } from 'graphql'
import { watch, computed, getCurrentScope, onScopeDispose } from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import { BaseHandler } from '#shared/server/apollo/handler/BaseHandler.ts'
import type {
  OperationQueryOptionsReturn,
  OperationQueryResult,
  QueryHandlerOptions,
  SubscribeToMoreOptions,
  SubscribeToMoreUpdateQueryOptions,
  WatchResultCallback,
} from '#shared/types/server/apollo/handler.ts'
import type { ReactiveFunction } from '#shared/types/utils.ts'

import type { ApolloClient, ErrorLike, ObservableQuery, OperationVariables } from '@apollo/client'
import type {
  ApolloQueryResultV4,
  UseQueryOptions,
  UseQueryReturn,
} from '@vue/apollo-composable/compat'
import type { ComputedRef, Ref, WatchStopHandle } from 'vue'

type SettledResult<TResult> = { data: Maybe<TResult>; error?: ErrorLike }

export default class QueryHandler<
  TResult = OperationQueryResult,
  TVariables extends OperationVariables = OperationVariables,
  TOptions extends QueryHandlerOptions = QueryHandlerOptions,
> extends BaseHandler<TResult, TVariables, UseQueryReturn<TResult, TVariables>, TOptions> {
  private lastCancel: (() => void) | null = null

  private loadCalled = false

  protected initialize(): void {
    super.initialize()

    this.setupReconnectionHandler()
  }

  private setupReconnectionHandler(): void {
    if (!this.handlerOptions.triggerRefetchOnConnectionReconnect) return

    useOnEmitter('reconnected', () => {
      if (
        (typeof this.handlerOptions.triggerRefetchOnConnectionReconnect === 'function' &&
          this.handlerOptions.triggerRefetchOnConnectionReconnect()) ||
        this.handlerOptions.triggerRefetchOnConnectionReconnect
      ) {
        this.refetch()
      }
    })
  }

  /**
   * Like `loading()`, but returns false when the Apollo cache already holds
   * data for this exact query + variables. Use this instead of `loading()`
   * in places where showing a spinner on the initial render would cause a
   * visible flicker (e.g. page-level skeleton states with `cache-and-network`).
   *
   * For explicit refetch / fetchMore operations, use `loading()` as usual.
   */
  public loadingWithoutCachedResult(): ComputedRef<boolean> {
    return computed(() => {
      if (!this.operationResult.loading.value) return false

      // vue-apollo may briefly yield undefined result even when the cache is
      // complete — keep showing the loader until the result ref is populated.
      return this.operationResult.result.value === undefined
    })
  }

  /**
   * Resolves once the query has settled its first load — a result was received
   * (or served from the cache) or it errored. Handy to await a reactive
   * `useQuery` handler (e.g. in a route guard) before reading its result;
   * resolves immediately when it has already settled. Unlike
   * `watchOnceOnResult`, it also resolves on an error, so an awaiting caller
   * never hangs.
   */
  public loaded(): Promise<void> {
    const loading = this.loadingWithoutCachedResult()

    if (!loading.value) return Promise.resolve()

    return new Promise((resolve) => {
      const stop = watch(loading, (isLoading) => {
        if (isLoading) return

        stop()
        resolve()
      })
    })
  }

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
    options: Partial<Omit<ApolloClient.QueryOptions<TResult, TVariables>, 'query'>> = {},
  ) {
    const {
      options: defaultOptions,
      document: { value: node },
    } = this.operationResult
    if (import.meta.env.DEV && !node) {
      throw new Error(`No query document available.`)
    }
    if (import.meta.env.DEV && !('load' in this.operationResult)) {
      let error = `${getOperationAST(node!)?.name?.value} is initialized with "useQuery" instead of "useLazyQuery". `
      error += `If you need to get the value immediately with ".query()", use "useLazyQuery" instead to not start extra network requests. `
      error += `"useQuery" should be used inside components to dynamically react to changed data.`
      throw new Error(error)
    }
    this.cancel()
    const { client } = useApolloClient()
    const aborter = typeof AbortController !== 'undefined' ? new AbortController() : null
    this.lastCancel = () => aborter?.abort()
    const { fetchPolicy: defaultFetchPolicy, ...defaultOptionsValue } =
      defaultOptions.value ?? ({} as UseQueryOptions<TResult, TVariables>)
    const fetchPolicy =
      options.fetchPolicy ||
      (defaultFetchPolicy !== 'cache-and-network' ? defaultFetchPolicy : undefined)
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
      } as ApolloClient.QueryOptions<TResult, TVariables>)
    } catch (error) {
      // TODO: do we need to handleError here also in a genric way?

      return {
        data: null,
        error: error as ErrorLike,
      }
    } finally {
      this.lastCancel = null
    }
  }

  public options(): OperationQueryOptionsReturn<TResult, TVariables> {
    return this.operationResult.options
  }

  public result(): Readonly<Ref<TResult | undefined>> {
    return this.operationResult.result
  }

  public watchQuery(): Readonly<Ref<ObservableQuery<TResult, TVariables> | null | undefined>> {
    return this.operationResult.query
  }

  /**
   * Subscribes to a related subscription and merges its data into the query result.
   *
   * Unlike the raw composable, the options may be reactive: whenever the getter
   * yields new options or the underlying query is (re)created, the previous
   * subscription is closed and a new one is opened.
   *
   * Returns a function which stops the subscription; it is also stopped
   * automatically when the current effect scope is disposed.
   */
  public subscribeToMore<
    TSubscriptionVariables extends OperationVariables = TVariables,
    TSubscriptionData = TResult,
  >(
    options:
      | SubscribeToMoreOptions<TResult, TSubscriptionVariables, TSubscriptionData>
      | ReactiveFunction<
          SubscribeToMoreOptions<TResult, TSubscriptionVariables, TSubscriptionData>
        >,
  ): () => void {
    type Options = SubscribeToMoreOptions<TResult, TSubscriptionVariables, TSubscriptionData>
    type ApolloOptions = ObservableQuery.SubscribeToMoreOptions<
      TResult,
      TSubscriptionVariables,
      TSubscriptionData,
      TVariables
    >

    const getOptions = typeof options === 'function' ? options : () => options

    // Without an 'onError' callback, Apollo logs an unhandled subscription error
    //  to the console itself. Route it through the handler instead, so that an
    //  expected authentication error during logout stays quiet, while any other
    //  failure is still reported like the error of the query itself.
    //
    // The 'updateQuery' callback keeps the shape Zammad always used: the
    //  previous result as a whole and `null` or `undefined` for "no change".
    const toApolloOptions = ({ updateQuery, onError, ...rest }: Options): ApolloOptions =>
      ({
        ...rest,
        onError: (error: unknown) => {
          if (onError) return onError(toErrorLike(error))

          this.handleError(toErrorLike(error))
        },
        updateQuery: updateQuery
          ? (previousData: unknown, updateOptions: unknown) =>
              updateQuery(
                previousData as TResult | null,
                updateOptions as SubscribeToMoreUpdateQueryOptions<
                  TResult,
                  TSubscriptionVariables,
                  TSubscriptionData
                >,
              ) ?? undefined
          : undefined,
      }) as ApolloOptions

    let unsubscribe: (() => void) | undefined

    // vue-apollo ignores 'subscribeToMore' while the observable query does not
    //  exist yet (a lazy query before 'load()', a disabled query), so wait for it.
    const stopWatching = watch(
      [this.watchQuery(), getOptions] as const,
      ([query, resolvedOptions]) => {
        unsubscribe?.()
        unsubscribe = undefined

        if (!query) return

        unsubscribe = this.operationResult.subscribeToMore(toApolloOptions(resolvedOptions))
      },
      { immediate: true },
    )

    const stop = () => {
      unsubscribe?.()
      unsubscribe = undefined
      stopWatching()
    }

    if (getCurrentScope()) onScopeDispose(stop)

    return stop
  }

  /**
   * Never rejects: a failure is reported once through the error handling and resolves with its
   * error, since most callers neither await nor catch it and a rejection would go uncaught.
   */
  public async fetchMore(
    options: ObservableQuery.FetchMoreOptions<TResult, TVariables>,
  ): Promise<SettledResult<TResult>> {
    const fetchMore = this.operationResult.fetchMore(options)
    if (!fetchMore) return { data: null }

    try {
      const result = await fetchMore

      // Apollo hands the merged page to the query from a timeout set before this resolves, and
      //   drops it if another `fetchMore` starts first - callers read `result()` right after.
      await new Promise((delivered) => setTimeout(delivered))

      return { data: (result.data ?? null) as Maybe<TResult> }
    } catch (error) {
      const errorLike = toErrorLike(error)

      // A failed page leaves the query itself untouched, so `onError` never hears of it.
      if (errorLike.name !== 'AbortError') this.handleError(errorLike)

      return { data: null, error: errorLike }
    }
  }

  /**
   * Never rejects: a failure is reported once through the error handling and resolves with its
   * error, since most callers neither await nor catch it and a rejection would go uncaught.
   */
  public async refetch(variables?: Partial<TVariables>): Promise<SettledResult<TResult>> {
    const refetch = this.operationResult.refetch(variables as TVariables)
    if (!refetch) return { data: null }

    try {
      const result = await refetch

      return { data: result?.data ?? null }
    } catch (error) {
      // A failed refetch is the query's own error, `onError` already reported it.
      return { data: null, error: this.operationError().value ?? toErrorLike(error) }
    }
  }

  /**
   * Starts a lazy query. Does nothing for a query created with "useQuery".
   */
  public load(variables?: TVariables): void {
    const operation = this.operationResult as unknown as {
      load?: (document?: unknown, variables?: TVariables) => false | Promise<unknown>
    }

    if (typeof operation.load !== 'function') {
      return
    }

    this.loadCalled = true

    const result = operation.load(undefined, variables)
    if (result instanceof Promise) {
      // error is handled in BaseHandler
      result.catch(() => {})
    }
  }

  /**
   * True for a lazy query which was not loaded yet.
   */
  public isFirstRun(): boolean {
    return 'load' in this.operationResult && !this.loadCalled
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

  public watchOnResult(callback: WatchResultCallback<TResult>): WatchStopHandle {
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

  /**
   * Calls back with every new result, like vue-apollo v4 did: the state changes
   * which v5 reports in addition - no data yet, or the previous data repeated
   * while a refetch is loading - are left out.
   */
  public onResult(callback: (result: ApolloQueryResultV4<TResult>) => void) {
    let lastData: TResult | undefined

    return this.operationResult.onResult((result) => {
      if (result.data === undefined) return
      if (result.loading && result.data === lastData) return

      lastData = result.data

      callback(result)
    })
  }
}
