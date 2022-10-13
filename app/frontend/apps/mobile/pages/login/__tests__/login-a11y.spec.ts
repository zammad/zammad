// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'

describe('testing login a11y', () => {
  it('check that login view has all required landmarks', async () => {
    const view = await visitView('/login')

    expect(view.getByRole('main')).toBeInTheDocument() // <main />
    expect(view.getByRole('navigation')).toBeInTheDocument() // <nav />
    expect(view.getByRole('contentinfo')).toBeInTheDocument() // <footer />
  })
})
