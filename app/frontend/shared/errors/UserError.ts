// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { UserErrors, UserFieldError } from '@shared/types/error'

export default class UserError extends Error {
  public errors: UserErrors

  public generalErrors: ReadonlyArray<string>

  public fieldErrors: ReadonlyArray<UserFieldError>

  constructor(errors: UserErrors) {
    super()

    this.errors = errors
    this.generalErrors = errors
      .filter((error) => !error.field)
      .map((error) => error.message)
    this.fieldErrors = errors.filter(
      (error) => error.field,
    ) as ReadonlyArray<UserFieldError>

    // Set the prototype explicitly.
    Object.setPrototypeOf(this, new.target.prototype)
  }

  public getFieldErrorList(): Record<string, string> {
    return this.fieldErrors.reduce(
      (fieldErrorList: Record<string, string>, fieldError) => {
        fieldErrorList[fieldError.field] = fieldError.message

        return fieldErrorList
      },
      {},
    )
  }
}
