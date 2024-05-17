// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

describe('testing avatar a11y view', async () => {
  it('has no accessibility violations', async () => {
    await visitView('/personal-setting/avatar')

    const results = await axe(document.body)
    expect(results).toHaveNoViolations()
  })

  // TODO: some accessibility needs to be fixed.
  it.skip('has no accessibility violations with upload new avatar by file flyout', async () => {
    const view = await visitView('/personal-setting/avatar')

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })
    await view.events.upload(view.getByTestId('fileUploadInput'), file)

    await waitForNextTick()

    await view.findByRole('complementary', {
      name: 'Crop Image',
    })

    const results = await axe(document.body)
    expect(results).toHaveNoViolations()
  })
})
