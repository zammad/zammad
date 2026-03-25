// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { waitUntilApisResolved } from '#tests/support/utils.ts'

import { mockUserDetailsApis } from '#mobile/entities/user/__tests__/mocks/user-mocks.ts'

describe('testing user a11y', () => {
  it('has no accessibility violations', async () => {
    const { mockUser, mockAttributes, user } = mockUserDetailsApis()

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    expect(view.container).toBeAccessible()
  })
})
