// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { CombinedGraphQLErrors } from '@apollo/client/errors'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import UserError from '#shared/errors/UserError.ts'

import type { ErrorLike } from '@apollo/client'

export const handleUserErrors = (error: UserError | ErrorLike) => {
  if (error instanceof UserError) {
    useNotifications().notify({
      id: error.userErrorId,
      message: error.getFirstErrorMessage(),
      type: NotificationTypes.Error,
    })
  }
}

// The backend's exception class of a failed operation, e.g. 'Exceptions::Forbidden'.
export const getGraphQLErrorType = (error: unknown): string | undefined => {
  if (!CombinedGraphQLErrors.is(error)) return undefined

  const type = error.errors[0]?.extensions?.type

  return typeof type === 'string' ? type : undefined
}

// Re-labels the fields of a user error, for forms whose field names differ from the attribute
//   paths the backend reports its validation errors under — an error on a nested record
//   (`translations.title`) or on a snake_case column (`parent_id`) matches no field of a form
//   that calls them `title` and `parentId`. `setErrors()` cannot resolve such a name to a field
//   node and promotes the message to a form-level error, detached from the field the user has to
//   correct.
//
// Fields that are not listed are passed through unchanged, and anything that is not a user error
//   is returned as it is, so a caller can rethrow the result of a `catch` unconditionally.
export const remapUserErrorFields = <T>(error: T, fieldMapping: Record<string, string>): T => {
  if (!(error instanceof UserError)) return error

  const remapped = error.errors.map((singleError) =>
    singleError.field && fieldMapping[singleError.field]
      ? { ...singleError, field: fieldMapping[singleError.field] }
      : singleError,
  )

  return new UserError(remapped, error.userErrorId) as T
}
