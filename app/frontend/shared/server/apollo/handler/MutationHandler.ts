// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import UserError from '#shared/errors/UserError.ts'
import type { UserErrors } from '#shared/types/error.ts'
import type { OperationMutationResult } from '#shared/types/server/apollo/handler.ts'

import { BaseHandler } from './BaseHandler.ts'

import type { OperationVariables } from '@apollo/client/core'
import type { UseMutationReturn } from '@vue/apollo-composable'
import type { Ref } from 'vue'

export default class MutationHandler<
  TResult = OperationMutationResult,
  TVariables extends OperationVariables = OperationVariables,
> extends BaseHandler<TResult, TVariables, UseMutationReturn<TResult, TVariables>> {
  public async send(
    variables?: TVariables,
    options?: Parameters<UseMutationReturn<TResult, TVariables>['mutate']>[1],
  ): Promise<Maybe<TResult>> {
    return new Promise((resolve, reject) => {
      this.operationResult.mutate(variables, options).then((result) => {
        if (!result) {
          return reject(this.operationError().value)
        }

        if (result.data) {
          const firstValue = Object.values(result.data)[0] as any
          // firstValue can be null when the mutation field returned null
          // (e.g. exception in backend resolver). Destructure safely.
          const errors: UserErrors | undefined = firstValue?.errors

          if (errors?.length) {
            const userErrors = new UserError(errors, this.handlerId)
            return reject(userErrors)
          }
        }

        // Handle top-level GraphQL errors (e.g. exception from backend
        // like the 50-participant cap). These are in result.errors, not
        // in result.data.*.errors, and do not reject the promise with
        // any errorPolicy setting (only network errors reject).
        if ((result as any).errors?.length) {
          const userErrors = new UserError(
            (result as any).errors.map((e: any) => ({ message: e.message })),
            this.handlerId,
          )
          return reject(userErrors)
        }

        return resolve(result.data || null)
      }).catch((err) => { return reject(err) })
    })
  }

  public called(): Ref<boolean> {
    return this.operationResult.called
  }
}
