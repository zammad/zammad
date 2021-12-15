// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { FetchResult, OperationVariables } from '@apollo/client/core'
import BaseHandler from '@common/server/apollo/handler/BaseHandler'
import {
  OperationSubscriptionOptionsReturn,
  OperationSubscriptionsResult,
  WatchResultCallback,
} from '@common/types/server/apollo/handler'
import { UseSubscriptionReturn } from '@vue/apollo-composable'
import { Ref, watch } from 'vue'

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
