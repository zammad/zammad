// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { CombinedGraphQLErrors } from '@apollo/client/errors'

import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import type {
  BaseHandlerOptions,
  CommonHandlerOptions,
  CommonHandlerOptionsParameter,
  OperationResult,
  OperationReturn,
} from '#shared/types/server/apollo/handler.ts'
import getUuid from '#shared/utils/getUuid.ts'

import type { ErrorLike, OperationVariables } from '@apollo/client'
import type { Ref } from 'vue'

export abstract class BaseHandler<
  TResult = OperationResult,
  TVariables extends OperationVariables = OperationVariables,
  TOperationReturn extends OperationReturn<TResult, TVariables> = OperationReturn<
    TResult,
    TVariables
  >,
  THandlerOptions = BaseHandlerOptions,
> {
  public operationResult!: TOperationReturn

  protected baseHandlerOptions: BaseHandlerOptions = {
    errorShowNotification: true,
    errorShowNotificationOnNotAuthorized: false,
    errorNotificationMessage: '',
    errorNotificationType: NotificationTypes.Error,
  }

  public handlerOptions!: CommonHandlerOptions<THandlerOptions>

  protected handlerId: string

  constructor(
    operationResult: TOperationReturn,
    handlerOptions?: CommonHandlerOptionsParameter<THandlerOptions>,
  ) {
    this.operationResult = operationResult

    this.handlerOptions = this.mergedHandlerOptions(handlerOptions)

    this.handlerId = getUuid()

    this.initialize()
  }

  protected initialize(): void {
    this.operationResult.onError((error) => {
      this.handleError(error)
    })
  }

  public loading(): Readonly<Ref<boolean>> {
    return this.operationResult.loading
  }

  // `null` without an error on compat, `undefined` on native.
  public operationError(): Readonly<Ref<Maybe<ErrorLike> | undefined>> {
    return this.operationResult.error
  }

  public onError(callback: (error: ErrorLike) => void): void {
    this.operationResult.onError(callback)
  }

  protected handleError(error: ErrorLike): void {
    const options = this.handlerOptions

    let triggerNotification = options.errorShowNotification

    let errorHandler: GraphQLHandlerError

    if (CombinedGraphQLErrors.is(error)) {
      const { message, extensions } = error.errors[0] ?? {}
      let type = (extensions?.type as GraphQLErrorTypes) || GraphQLErrorTypes.UnknownError

      // When it's not a known type, use the unknown error type.
      if (!Object.values(GraphQLErrorTypes).includes(type)) {
        type = GraphQLErrorTypes.UnknownError
      }

      errorHandler = {
        type,
        message,
      }
    } else {
      // Anything that is not a GraphQL response error came from the transport.
      errorHandler = {
        type: GraphQLErrorTypes.NetworkError,
      }
    }

    if (options.errorCallback) {
      const trigger = options.errorCallback(errorHandler)

      if (typeof trigger === 'boolean') {
        triggerNotification = trigger
      }
    }

    // Never notify about an authentication error unless the operation opted in,
    //  no matter what the error callback decided: the invalid session is handled
    //  centrally and the user ends up on the login screen anyway. This is
    //  checked after the error callback, because callbacks are usually written
    //  as a filter for specific error types and would otherwise switch the
    //  notification on again.
    if (
      errorHandler.type === GraphQLErrorTypes.NotAuthorized &&
      !options.errorShowNotificationOnNotAuthorized
    ) {
      triggerNotification = false
    }

    if (triggerNotification) {
      // TODO enable and fix all tests
      // if (import.meta.env.DEV) {
      //   console.error(error)
      // }
      useNotifications().notify({
        id: this.handlerId, // TODO maybe for network error we should have the same id for all?
        message: this.errorNotificationMessage(errorHandler.type, errorHandler.message),
        type: options.errorNotificationType,
      })
    }
  }

  protected mergedHandlerOptions(
    handlerOptions?: CommonHandlerOptionsParameter<THandlerOptions>,
  ): CommonHandlerOptions<THandlerOptions> {
    // The merged type is always safe as a 'CommonHandlerOptions<THandlerOptions>' type.
    return Object.assign(
      this.baseHandlerOptions,
      handlerOptions,
    ) as CommonHandlerOptions<THandlerOptions>
  }

  private errorNotificationMessage(errorType: GraphQLErrorTypes, errorMessage?: string): string {
    const defaultErrorNotificationMessage = __('An error occurred during the operation.')

    const fallbackErrorMessage =
      errorType === GraphQLErrorTypes.UnknownError || !errorMessage
        ? defaultErrorNotificationMessage
        : errorMessage

    return this.handlerOptions.errorNotificationMessage || fallbackErrorMessage
  }
}
