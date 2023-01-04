// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'
import type { UseMutationReturn } from '@vue/apollo-composable'
import type { OperationVariables } from '@apollo/client/core'
import UserError from '@shared/errors/UserError'
import type { OperationMutationResult } from '@shared/types/server/apollo/handler'
import BaseHandler from './BaseHandler'

export default class MutationHandler<
  TResult = OperationMutationResult,
  TVariables = OperationVariables,
> extends BaseHandler<
  TResult,
  TVariables,
  UseMutationReturn<TResult, TVariables>
> {
  public async send(variables?: TVariables): Promise<Maybe<TResult>> {
    return new Promise((resolve, reject) => {
      this.operationResult.mutate(variables).then((result) => {
        if (!result) {
          return reject(this.operationError().value)
        }

        if (result.data) {
          const { errors } = Object.values(result.data)[0] as {
            errors: UserError[]
          }

          if (errors) {
            const userErrors = new UserError(errors)

            return reject(userErrors)
          }
        }

        return resolve(result.data || null)
      })
    })
  }

  public called(): Ref<boolean> {
    return this.operationResult.called
  }
}
