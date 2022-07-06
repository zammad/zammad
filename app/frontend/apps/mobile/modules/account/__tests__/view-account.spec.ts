// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'

describe('account page', () => {
  // TODO pretty much static page, not a lot of tests needed for now
  it('can view my account page', async () => {
    mockAccount({
      lastname: 'Doe',
      firstname: 'John',
    })

    const view = await visitView('/account')

    const mainContent = view.getByTestId('appMain')
    expect(mainContent, 'have avatar').toHaveTextContent('JD')
    expect(mainContent, 'have my name').toHaveTextContent('John Doe')
    expect(mainContent, 'have logout button').toHaveTextContent('Sign out')
  })
})
