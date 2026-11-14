// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import type {
  OperationSubscriptionOptionsReturn,
  OperationSubscriptionsResult,
  SubscriptionHandlerResult,
  SubscriptionOperationReturn,
  WatchResultCallback,
} from '#shared/types/server/apollo/handler.ts'

import { BaseHandler } from './BaseHandler.ts'

import type { OperationVariables } from '@apollo/client'
import type { Ref, WatchStopHandle } from 'vue'

export default class SubscriptionHandler<
  TResult = OperationSubscriptionsResult,
  TVariables extends OperationVariables = OperationVariables,
> extends BaseHandler<TResult, TVariables, SubscriptionOperationReturn<TResult, TVariables>> {
  public subscribed = false

  public options(): OperationSubscriptionOptionsReturn<TResult, TVariables> {
    return this.operationResult.options
  }

  public start(): void {
    this.operationResult.start()
  }

  public stop(): void {
    this.operationResult.stop()
  }

  // Resolves once the new subscription is open - callers must not rely on
  // synchronous completion.
  public async restart(): Promise<void> {
    await this.operationResult.restart()
  }

  public result(): Readonly<Ref<Maybe<TResult> | undefined>> {
    return this.operationResult.result
  }

  public onResult(callback: (result: SubscriptionHandlerResult<TResult>) => void) {
    // The event hands the data directly; keep the v4 `{ data }` payload shape
    // for the callers. Cast: vueuse's `Callback<TResult>` is a conditional type
    // that stays unresolved on the open generic and accepts no callback at all.
    const onResult = this.operationResult.onResult as (fn: (data: TResult) => void) => {
      off: () => void
    }

    return onResult((data) => callback({ data }))
  }

  public async onSubscribed(): Promise<Maybe<TResult> | undefined> {
    return new Promise((resolve, reject) => {
      // eslint-disable-next-line prefer-const
      let errorUnsubscribe!: () => void
      // eslint-disable-next-line prefer-const
      let resultUnsubscribe!: () => void

      const onFirstResultLoaded = () => {
        resultUnsubscribe()
        errorUnsubscribe()
      }

      resultUnsubscribe = watch(this.result(), (result) => {
        this.subscribed = true

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
}
