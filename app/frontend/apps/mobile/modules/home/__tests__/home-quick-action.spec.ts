// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'

describe('testing home section menu', () => {
  it('home icon is highlighted on home page', async () => {
    const view = await visitView('/')

    expect(view.getByIconName('plus')).toBeInTheDocument()

    // TODO: Check on ticket create form, when route exists
    // await view.events.click(quickAction)

    // await waitFor(() => {
    //   expect(view.getByText('TODO')).toBeInTheDocument()
    // })
  })
})
