// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ApolloError, OperationVariables } from '@apollo/client/core'
import {
  BaseHandlerOptions,
  CommonHandlerOptions,
  CommonHandlerOptionsParameter,
  OperationResult,
  OperationReturn,
} from '@common/types/server/apollo/handler'
import { Ref } from 'vue'
import useNotifications from '@common/composables/useNotifications'
import { NotificationTypes } from '@common/types/notification'
import {
  GraphQLErrorReport,
  GraphQLErrorTypes,
  GraphQLHandlerError,
} from '@common/types/error'

export default abstract class BaseHandler<
  TResult = OperationResult,
  TVariables = OperationVariables,
  TOperationReturn extends OperationReturn<
    TResult,
    TVariables
  > = OperationReturn<TResult, TVariables>,
  THandlerOptions = BaseHandlerOptions,
> {
  public operationResult!: TOperationReturn

  protected baseHandlerOptions: BaseHandlerOptions = {
    errorShowNotification: true,
    errorNotitifactionMessage: __(
      'An error occured during the operation. Please contact your administrator.',
    ),
    errorNotitifactionType: NotificationTypes.ERROR,
  }

  public handlerOptions!: CommonHandlerOptions<THandlerOptions>

  constructor(
    operationResult: TOperationReturn,
    handlerOptions?: CommonHandlerOptionsParameter<THandlerOptions>,
  ) {
    this.operationResult = operationResult

    this.handlerOptions = this.mergedHandlerOptions(handlerOptions)

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

  protected handleError(error: ApolloError): void {
    const options = this.handlerOptions

    if (options.errorShowNotification) {
      const { notify } = useNotifications()

      notify({
        message: options.errorNotitifactionMessage,
        type: options.errorNotitifactionType,
      })
    }

    if (options.errorCallback) {
      const { graphQLErrors, networkError } = error
      let errorHandler: GraphQLHandlerError

      if (graphQLErrors.length > 0) {
        const { message, extensions }: GraphQLErrorReport = graphQLErrors[0]
        errorHandler = {
          type:
            (extensions?.type as GraphQLErrorTypes) ||
            GraphQLErrorTypes.NetworkError,
          message,
        }
      } else if (networkError) {
        errorHandler = {
          type: GraphQLErrorTypes.NetworkError,
        }
      } else {
        errorHandler = {
          type: GraphQLErrorTypes.UnkownError,
        }
      }
      options.errorCallback(errorHandler)
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
}
