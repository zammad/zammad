// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'

describe('account page', () => {
  // TODO pretty much static page, not a lot of tests needed for now
  test('can view my account page', async () => {
    mockAccount({
      lastname: 'Doe',
      firstname: 'John',
    })

    const view = await visitView('/account')

    expect(view.getByText('JD'), 'have avatar').toBeInTheDocument()
    expect(view.getByText('John Doe'), 'have my name').toBeInTheDocument()

    expect(view.getByText('Sign out'), 'have logout button').toBeInTheDocument()
  })
})
