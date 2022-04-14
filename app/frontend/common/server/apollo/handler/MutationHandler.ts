// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { OperationVariables } from '@apollo/client/core'
import UserError from '@common/errors/UserError'
import BaseHandler from '@common/server/apollo/handler/BaseHandler'
import { OperationMutationResult } from '@common/types/server/apollo/handler'
import { UseMutationReturn } from '@vue/apollo-composable'
import { Ref } from 'vue'

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
