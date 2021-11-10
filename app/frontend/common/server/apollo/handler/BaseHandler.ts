// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import log from '@common/utils/log'
import { ApolloError, OperationVariables } from '@apollo/client/core'
import {
  BaseHandlerOptions,
  CommonHandlerOptions,
  CommonHandlerOptionsParameter,
  OperationFunction,
  OperationOptions,
  OperationResult,
  OperationReturn,
  OperationVariablesParameter,
} from '@common/types/server/apollo/handler'
import { Ref } from 'vue'
import useNotifications from '@common/composables/useNotifications'
import {
  GraphQLErrorExtensionsHandler,
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
  TOperationFunction extends OperationFunction<
    TResult,
    TVariables
  > = OperationFunction<TResult, TVariables>,
  TOperationOptions extends OperationOptions<
    TResult,
    TVariables
  > = OperationOptions<TResult, TVariables>,
  THandlerOptions = BaseHandlerOptions,
> {
  protected operation: TOperationFunction

  public operationResult!: TOperationReturn

  protected baseHandlerOptions: BaseHandlerOptions = {
    errorShowNotification: true,
    errorNotitifactionMessage:
      'An error occured during the operation. Please contact your administrator.',
    errorNotitifactionType: 'error',
    errorLogLevel: 'error',
  }

  protected handlerOptions!: CommonHandlerOptions<THandlerOptions>

  public error: Maybe<GraphQLHandlerError> = null

  constructor(
    operation: TOperationFunction,
    variables?: OperationVariablesParameter<TVariables>,
    options?: TOperationOptions,
    handlerOptions?: CommonHandlerOptionsParameter<THandlerOptions>,
  ) {
    this.operation = operation

    this.handlerOptions = this.mergedHandlerOptions(handlerOptions)

    this.execute(variables, options)
  }

  public execute(
    variables?: OperationVariablesParameter<TVariables>,
    options?: TOperationOptions,
  ): void {
    this.operationResult = this.operationExecute(variables, options)

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

  protected abstract operationExecute(
    variables?: OperationVariablesParameter<TVariables>,
    options?: TOperationOptions,
  ): TOperationReturn

  protected handleError(error: ApolloError): void {
    const options = this.handlerOptions

    if (options.errorShowNotification) {
      const notification = useNotifications()

      notification.notify({
        message: options.errorNotitifactionMessage,
        type: options.errorNotitifactionType,
      })
    }

    // TODO: Maybe it's also a option to use the error-Link from the apollo client for the general error output.
    // Downside would be, that the error messages can not be avoided for a single query/mutation if i saw it correctly (but this is maybe
    // only needed for some special things, like the first session id check).
    const errorMessagePrefix = '[GraphQLClient]'
    const { graphQLErrors, networkError } = error

    if (graphQLErrors.length > 0) {
      const { message, extensions }: GraphQLErrorReport = graphQLErrors[0]
      const { type, backtrace }: GraphQLErrorExtensionsHandler = {
        type: extensions?.type || GraphQLErrorTypes.NetworkError,
        backtrace: extensions?.backtrace,
      }

      this.error = {
        message: `${errorMessagePrefix} GraphQL error - ${message}`,
        type,
        backtrace,
      }
    } else if (networkError) {
      this.error = {
        type: GraphQLErrorTypes.NetworkError,
        message: `${errorMessagePrefix} Network error - ${networkError}`,
      }
    } else {
      this.error = {
        type: GraphQLErrorTypes.UnkownError,
        message: 'Unknown error.',
      }
    }

    if (options.errorLogLevel !== 'silent') {
      const errorMessages: Array<string> = [this.error.message]

      if (this.error.backtrace) {
        errorMessages.push(this.error.backtrace)
      }

      log[options.errorLogLevel](...errorMessages)
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

  public abstract onLoaded(): Promise<Maybe<TResult>>

  // TODO: Maybe we can add a pick func
  public loadedResult(): Promise<Maybe<TResult>> {
    return this.onLoaded()
      .then((data: Maybe<TResult>) => data)
      .catch(() => null)
  }
}
