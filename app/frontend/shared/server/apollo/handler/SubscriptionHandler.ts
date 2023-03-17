// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ref, WatchStopHandle } from 'vue'
import { watch } from 'vue'
import type { FetchResult, OperationVariables } from '@apollo/client/core'
import type {
  OperationSubscriptionOptionsReturn,
  OperationSubscriptionsResult,
  WatchResultCallback,
} from '@shared/types/server/apollo/handler'
import type { UseSubscriptionReturn } from '@vue/apollo-composable'
import BaseHandler from './BaseHandler'

export default class SubscriptionHandler<
  TResult = OperationSubscriptionsResult,
  TVariables = OperationVariables,
> extends BaseHandler<
  TResult,
  TVariables,
  UseSubscriptionReturn<TResult, TVariables>
> {
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

  public result(): Ref<Maybe<TResult> | undefined> {
    return this.operationResult.result
  }

  public onResult(
    callback: (
      result: FetchResult<
        TResult,
        Record<string, unknown>,
        Record<string, unknown>
      >,
    ) => void,
  ) {
    this.operationResult.onResult(callback)
  }

  public async onSubscribed(): Promise<Maybe<TResult> | undefined> {
    return new Promise((resolve, reject) => {
      let errorUnsubscribe!: () => void
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
}
