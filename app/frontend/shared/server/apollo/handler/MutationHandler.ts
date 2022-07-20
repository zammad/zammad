// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
      this.operationResult
        .mutate(variables)
        .then((result) => {
          if (result?.data) {
            const { errors } = Object.values(result.data)[0]

            if (errors) {
              const userErrors = new UserError(errors)

              return reject(userErrors)
            }
          }
          return resolve(result?.data || null)
        })
        .catch(() => reject(this.operationError().value))
    })
  }

  public called(): Ref<boolean> {
    return this.operationResult.called
  }
}
