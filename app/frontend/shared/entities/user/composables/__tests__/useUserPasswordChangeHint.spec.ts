// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type { EditableUser } from '#shared/entities/user/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useUserPasswordChangeHint } from '../useUserPasswordChangeHint.ts'

const hint = 'The user will be notified of the password change by email.'

const buildUser = (user: Partial<EditableUser> = {}) =>
  ({
    id: convertToGraphQLId('User', 5),
    email: 'nicole.braun@zammad.org',
    ...user,
  }) as EditableUser

const setup = (user: EditableUser) => {
  const formChangeFields: Record<string, Partial<FormSchemaField>> = {}
  const { updatePasswordChangeHint } = useUserPasswordChangeHint(user, formChangeFields)

  return { formChangeFields, updatePasswordChangeHint }
}

describe('useUserPasswordChangeHint', () => {
  beforeEach(() => {
    mockUserCurrent({ id: convertToGraphQLId('User', 2) })
  })

  it('shows the hint while a password is entered', () => {
    const { formChangeFields, updatePasswordChangeHint } = setup(buildUser())

    updatePasswordChangeHint('password', 'vXqXseF9L2ab')
    expect(formChangeFields.password?.help).toBe(hint)

    updatePasswordChangeHint('password', '')
    expect(formChangeFields.password?.help).toBe('')
  })

  it('ignores unrelated fields', () => {
    const { formChangeFields, updatePasswordChangeHint } = setup(buildUser())

    updatePasswordChangeHint('firstname', 'Thomas')
    expect(formChangeFields.password).toBeUndefined()
  })

  it('shows the hint for a user without email only once an email is entered', () => {
    const { formChangeFields, updatePasswordChangeHint } = setup(buildUser({ email: '' }))

    updatePasswordChangeHint('password', 'vXqXseF9L2ab')
    expect(formChangeFields.password?.help).toBe('')

    updatePasswordChangeHint('email', 'nicole.braun@zammad.org')
    expect(formChangeFields.password?.help).toBe(hint)
  })

  it('keeps the hint when the previous email is removed', () => {
    const { formChangeFields, updatePasswordChangeHint } = setup(buildUser())

    updatePasswordChangeHint('password', 'vXqXseF9L2ab')
    updatePasswordChangeHint('email', '')
    expect(formChangeFields.password?.help).toBe(hint)
  })

  it('does not show the hint when users edit themselves', () => {
    const { formChangeFields, updatePasswordChangeHint } = setup(
      buildUser({ id: convertToGraphQLId('User', 2) }),
    )

    updatePasswordChangeHint('password', 'vXqXseF9L2ab')
    expect(formChangeFields.password?.help).toBe('')
  })
})
