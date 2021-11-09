import { OperationVariables } from '@apollo/client/core'
import BaseHandler from '@common/server/apollo/handler/BaseHandler'
import {
  CommonHandlerOptions,
  OperationMutationFunction,
  OperationMutationOptions,
  OperationMutationOptionsWithoutVariables,
  OperationMutationResult,
  MutationHandlerOptions,
  OperationMutationVariablesParameter,
} from '@common/types/server/apollo/handler'
import { UseMutationOptions, UseMutationReturn } from '@vue/apollo-composable'

const additionalHandlerOptions: MutationHandlerOptions = {
  directSendMutation: true,
}

export default class MutationHandler<
  TResult = OperationMutationResult,
  TVariables = OperationVariables,
> extends BaseHandler<
  TResult,
  TVariables,
  UseMutationReturn<TResult, TVariables>,
  OperationMutationFunction<TResult, TVariables>,
  OperationMutationOptionsWithoutVariables<TResult, TVariables>,
  MutationHandlerOptions
> {
  protected mergedHandlerOptions(
    handlerOptions?: CommonHandlerOptions<MutationHandlerOptions>,
  ): CommonHandlerOptions<MutationHandlerOptions> {
    return Object.assign(
      this.baseHandlerOptions,
      additionalHandlerOptions,
      handlerOptions,
    )
  }

  public execute(
    variables?: OperationMutationVariablesParameter<TVariables>,
    options?: OperationMutationOptionsWithoutVariables<TResult, TVariables>,
  ): void {
    super.execute(variables, options)

    if (this.handlerOptions.directSendMutation) {
      // Variables are in the options for the direct sending situtation
      // and need not to given to the send function.
      this.send()
    }
  }

  public operationExecute(
    variables?: OperationMutationVariablesParameter<TVariables>,
    options?: OperationMutationOptionsWithoutVariables<TResult, TVariables>,
  ): UseMutationReturn<TResult, TVariables> {
    let operationOptions!: OperationMutationOptions<TResult, TVariables>

    // A special handling is needed when options or variables are given as a function.
    if (typeof options === 'function' || typeof variables === 'function') {
      operationOptions = (): UseMutationOptions<TResult, TVariables> => {
        const parsedOptions =
          typeof options === 'function' ? options() : options

        return {
          ...parsedOptions,
          variables: typeof variables === 'function' ? variables() : variables,
        }
      }
    } else {
      operationOptions = {
        ...options,
        variables,
      }
    }

    return this.operation(operationOptions)
  }

  public send(variables?: TVariables): void {
    this.operationResult.mutate(variables)
  }

  public async onLoaded(): Promise<Maybe<TResult>> {
    return new Promise((resolve, reject) => {
      this.operationResult.onDone((result) => {
        return resolve(result.data || null)
      })

      this.operationResult.onError(() => {
        return reject(this.operationError())
      })
    })
  }
}
