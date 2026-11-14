// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import UserError from '#shared/errors/UserError.ts'
import type { UserErrors } from '#shared/types/error.ts'
import type {
  MutationOperationReturn,
  MutationSendOptions,
  OperationMutationResult,
} from '#shared/types/server/apollo/handler.ts'

import { BaseHandler } from './BaseHandler.ts'

import type { OperationVariables } from '@apollo/client'
import type { Ref } from 'vue'

export default class MutationHandler<
  TResult = OperationMutationResult,
  TVariables extends OperationVariables = OperationVariables,
> extends BaseHandler<TResult, TVariables, MutationOperationReturn<TResult, TVariables>> {
  public async send(
    variables?: TVariables,
    options?: MutationSendOptions<TResult, TVariables>,
  ): Promise<Maybe<TResult>> {
    // `mutate` resolves `{ data, error }` instead of rejecting; `BaseHandler`
    // registers `onError`, so it never throws and the `result.error` branch
    // below is the real error path.
    const result = await this.operationResult.mutate({ ...options, variables })

    // The error itself was already reported to 'onError' by vue-apollo.
    if (result.error) {
      throw this.operationError().value ?? result.error
    }

    const payload = result.data ? Object.values(result.data)[0] : undefined
    const errors =
      payload && typeof payload === 'object' && 'errors' in payload
        ? (payload as { errors?: UserErrors }).errors
        : undefined

    if (errors?.length) {
      throw new UserError(errors, this.handlerId)
    }

    return result.data || null
  }

  public called(): Readonly<Ref<boolean>> {
    return this.operationResult.called
  }
}
