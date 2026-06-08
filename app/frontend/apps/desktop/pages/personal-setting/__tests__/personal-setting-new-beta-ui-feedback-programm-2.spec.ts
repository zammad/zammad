// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'

// Moving this spec to a separate file resolves issue of some inconsistent states.
// Occurring when running all personal-setting beta ui specs in one file.
describe('personal BETA UI settings - feedback program', () => {
  it('can reset "do not ask again" setting', async () => {
    localStorage.setItem('beta-ui-switch', 'true')

    localStorage.setItem('beta-ui-feedback-never-ask-again-timed', 'true')

    const view = await visitView('/personal-setting/new-beta-ui')

    expect(view.getByRole('heading', { name: 'BETA UI feedback program' })).toBeVisible()

    const checkbox = await view.findByRole('checkbox', {
      name: 'Do not ask automatically for feedback on the BETA UI',
    })

    expect(checkbox).toBeChecked()

    await view.events.click(checkbox)

    expect(checkbox).not.toBeChecked()

    await waitFor(() => {
      expect(localStorage.getItem('beta-ui-feedback-never-ask-again-timed')).toBe('false')
    })
  })
})
