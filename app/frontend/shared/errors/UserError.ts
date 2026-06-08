// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumUserErrorException } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import type { UserErrors, UserFieldError } from '#shared/types/error.ts'
import getUuid from '#shared/utils/getUuid.ts'

export default class UserError extends Error {
  public userErrorId: string

  public errors: UserErrors

  public generalErrors: ReadonlyArray<string>

  public fieldErrors: ReadonlyArray<UserFieldError>

  constructor(errors: UserErrors, userErrorId?: string) {
    super()

    this.userErrorId = userErrorId || getUuid()
    this.errors = errors
    this.generalErrors = errors.filter((error) => !error.field).map((error) => error.message)
    this.fieldErrors = errors.filter((error) => error.field) as ReadonlyArray<UserFieldError>

    // Set the prototype explicitly.
    Object.setPrototypeOf(this, new.target.prototype)
  }

  public getFirstErrorMessage(): string {
    return this.errors[0].message
  }

  public getFirstErrorException(): EnumUserErrorException | undefined | null {
    return this.errors[0].exception
  }

  public getFieldErrorList(): Record<string, string> {
    return this.fieldErrors.reduce((fieldErrorList: Record<string, string>, fieldError) => {
      // In case of an array with placeholders, translate the message right here.
      if (fieldError.messagePlaceholder)
        fieldErrorList[fieldError.field] = i18n.t(
          fieldError.message,
          ...fieldError.messagePlaceholder,
        )
      // Otherwise, just pass the source string for later translation.
      else fieldErrorList[fieldError.field] = fieldError.message

      return fieldErrorList
    }, {})
  }
}
