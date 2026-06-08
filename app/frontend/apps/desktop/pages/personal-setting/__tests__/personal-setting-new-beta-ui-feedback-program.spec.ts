// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

describe('personal BETA UI settings - feedback program', () => {
  beforeEach(() => {
    localStorage.clear()
    localStorage.setItem('beta-ui-switch', 'true')
  })

  it('shows join feedback program button when not yet consented', async () => {
    localStorage.setItem('beta-ui-switch', 'true')
    localStorage.setItem('beta-ui-feedback-consent', 'false')

    const view = await visitView('/personal-setting/new-beta-ui')

    await waitFor(() => {
      expect(view.queryByText('BETA UI feedback program')).toBeInTheDocument()
    })

    expect(view.getByRole('button', { name: 'Join feedback program' })).toBeInTheDocument()

    expect(view.queryByText('Give feedback')).not.toBeInTheDocument()
    expect(
      view.queryByText('You are part of the BETA UI feedback program.'),
    ).not.toBeInTheDocument()
  })

  it('joins feedback program when button is clicked', async () => {
    localStorage.setItem('beta-ui-switch', 'true')
    localStorage.setItem('beta-ui-feedback-consent', 'false')

    const view = await visitView('/personal-setting/new-beta-ui')

    const joinButton = await view.findByRole('button', { name: 'Join feedback program' })

    await view.events.click(joinButton)

    const consentDialog = await view.findByRole('dialog', {
      name: 'Want to join the BETA UI feedback program?',
    })

    expect(consentDialog).toBeVisible()

    const agreeButton = view.getByRole('button', { name: 'Agree & join' })

    await view.events.click(agreeButton)

    expect(view.getByText('You are part of the BETA UI feedback program.')).toBeInTheDocument()
  })

  it('shows feedback program status when consented', async () => {
    localStorage.setItem('beta-ui-switch', 'true')
    localStorage.setItem('beta-ui-feedback-consent', 'true')

    const view = await visitView('/personal-setting/new-beta-ui')

    expect(view.getByText('You are part of the BETA UI feedback program.')).toBeInTheDocument()
    expect(view.getByText('Leave program')).toBeInTheDocument()
    expect(view.getByText('Give feedback')).toBeInTheDocument()

    expect(view.queryByText('Join feedback program')).not.toBeInTheDocument()
  })

  it('leaves feedback program with confirmation', async () => {
    localStorage.setItem('beta-ui-switch', 'true')
    localStorage.setItem('beta-ui-feedback-consent', 'true')

    const view = await visitView('/personal-setting/new-beta-ui')

    const leaveButton = view.getByText('Leave program')

    await view.events.click(leaveButton)

    const confirmationDialog = await view.findByRole('dialog', {
      name: 'Leave BETA UI feedback program?',
    })

    expect(confirmationDialog).toBeVisible()
    expect(view.getByText('You can always re-join later.')).toBeInTheDocument()

    const dialog = await view.findByRole('dialog', { name: 'Leave BETA UI feedback program?' })

    await view.events.click(within(dialog).getByRole('button', { name: 'Leave program' }))

    await waitFor(() => {
      expect(localStorage.getItem('beta-ui-feedback-consent')).toBe('false')
    })

    expect(view.getByText('Join feedback program')).toBeInTheDocument()
  })

  it('hides feedback program section when not on beta UI', async () => {
    localStorage.setItem('beta-ui-switch', 'false')
    localStorage.setItem('beta-ui-feedback-consent', 'false')

    const view = await visitView('/personal-setting/new-beta-ui')

    expect(view.queryByText('BETA UI feedback program')).not.toBeInTheDocument()
    expect(view.queryByText('Join feedback program')).not.toBeInTheDocument()
  })
})
