// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import type { EditableUser } from '#shared/entities/user/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useUserEdit } from '../composables/useUserEdit.ts'

const openDialog = vi.fn()

vi.mock('#mobile/components/CommonDialogObjectForm/useDialogObjectForm.ts', () => ({
  useDialogObjectForm: () => ({ openDialog }),
}))

describe('useUserEdit', () => {
  beforeEach(() => {
    mockUserCurrent({ id: convertToGraphQLId('User', 2) })
    openDialog.mockReset()
  })

  it('shows a hint that the user will be notified of the password change', async () => {
    const { openEditUserDialog } = useUserEdit()

    await openEditUserDialog({
      id: convertToGraphQLId('User', 5),
      email: 'nicole.braun@zammad.org',
    } as EditableUser)

    const { formChangeFields, onChangedField } = openDialog.mock.calls[0][0]

    onChangedField('password', 'vXqXseF9L2ab')

    expect(formChangeFields.password.help).toBe(
      'The user will be notified of the password change by email.',
    )
  })
})
