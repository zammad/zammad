// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { mockUserDetailsApis } from '#mobile/entities/user/__tests__/mocks/user-mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { waitUntilApisResolved } from '#tests/support/utils.ts'

describe('testing user a11y', () => {
  it('has no accessibility violations', async () => {
    const { mockUser, mockAttributes, user } = mockUserDetailsApis()

    const view = await visitView(`/users/${user.internalId}`)

    await waitUntilApisResolved(mockUser, mockAttributes)

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
