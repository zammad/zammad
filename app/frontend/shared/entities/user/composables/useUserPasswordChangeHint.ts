// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldValue, FormSchemaField } from '#shared/components/Form/types.ts'
import type { EditableUser } from '#shared/entities/user/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

export const useUserPasswordChangeHint = (
  user: EditableUser,
  formChangeFields: Record<string, Partial<FormSchemaField>>,
) => {
  const session = useSessionStore()

  let password = ''
  let { email } = user

  const updatePasswordChangeHint = (fieldName: string, newValue: FormFieldValue) => {
    if (fieldName !== 'password' && fieldName !== 'email') return

    if (fieldName === 'password') password = (newValue as string) || ''
    else email = (newValue as string) || ''

    // Users changing their own password are not notified by this path.
    const isNotified = Boolean(password && session.userId !== user.id && (email || user.email))

    formChangeFields.password ||= {}
    formChangeFields.password.help = isNotified
      ? __('The user will be notified of the password change by email.')
      : ''
  }

  return { updatePasswordChangeHint }
}
