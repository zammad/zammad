// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import type {
  GraphQLErrorReport,
  GraphQLHandlerError,
} from '#shared/types/error.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import type {
  BaseHandlerOptions,
  CommonHandlerOptions,
  CommonHandlerOptionsParameter,
  OperationResult,
  OperationReturn,
} from '#shared/types/server/apollo/handler.ts'
import getUuid from '#shared/utils/getUuid.ts'

import type { ApolloError, OperationVariables } from '@apollo/client/core'
import type { Ref } from 'vue'

export default abstract class BaseHandler<
  TResult = OperationResult,
  TVariables extends OperationVariables = OperationVariables,
  TOperationReturn extends OperationReturn<
    TResult,
    TVariables
  > = OperationReturn<TResult, TVariables>,
  THandlerOptions = BaseHandlerOptions,
> {
  public operationResult!: TOperationReturn

  protected baseHandlerOptions: BaseHandlerOptions = {
    errorShowNotification: true,
    errorNotificationMessage: '',
    errorNotificationType: NotificationTypes.Error,
  }

  public handlerOptions!: CommonHandlerOptions<THandlerOptions>

  private handlerId: string

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

  public loading(): Ref<boolean> {
    return this.operationResult.loading
  }

  public operationError(): Ref<Maybe<ApolloError>> {
    return this.operationResult.error
  }

  public onError(callback: (error: ApolloError) => void): void {
    this.operationResult.onError(callback)
  }

  protected handleError(error: ApolloError): void {
    const options = this.handlerOptions

    let triggerNotification = options.errorShowNotification

    const { graphQLErrors, networkError } = error
    let errorHandler: GraphQLHandlerError

    if (graphQLErrors.length > 0) {
      const { message, extensions }: GraphQLErrorReport = graphQLErrors[0]
      let type =
        (extensions?.type as GraphQLErrorTypes) ||
        GraphQLErrorTypes.UnknownError

      // When it's not a known type, use the unknown error type.
      if (!Object.values(GraphQLErrorTypes).includes(type)) {
        type = GraphQLErrorTypes.UnknownError
      }

      errorHandler = {
        type,
        message,
      }
    } else if (networkError) {
      errorHandler = {
        type: GraphQLErrorTypes.NetworkError,
      }
    } else {
      errorHandler = {
        type: GraphQLErrorTypes.UnknownError,
      }
    }

    if (errorHandler.type === GraphQLErrorTypes.NotAuthorized) {
      triggerNotification = false
    }

    if (options.errorCallback) {
      const trigger = options.errorCallback(errorHandler)

      if (typeof trigger === 'boolean') {
        triggerNotification = trigger
      }
    }

    if (triggerNotification) {
      // TODO enable and fix all tests
      // if (import.meta.env.DEV) {
      //   console.error(error)
      // }
      useNotifications().notify({
        id: this.handlerId,
        message: this.errorNotificationMessage(
          errorHandler.type,
          errorHandler.message,
        ),
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

  private errorNotificationMessage(
    errorType: GraphQLErrorTypes,
    errorMessage?: string,
  ): string {
    const defaultErrorNotificationMessage = __(
      'An error occured during the operation.',
    )

    const fallbackErrorMessage =
      errorType === GraphQLErrorTypes.UnknownError || !errorMessage
        ? defaultErrorNotificationMessage
        : errorMessage

    return this.handlerOptions.errorNotificationMessage || fallbackErrorMessage
  }
}
