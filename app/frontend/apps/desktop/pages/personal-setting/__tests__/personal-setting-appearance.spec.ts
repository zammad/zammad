// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { waitForAccountAppearanceMutationCalls } from '../graphql/mutations/accountAppearance.mocks.ts'

describe('appearance page', () => {
  it('update appearance to dark', async () => {
    const view = await visitView('/personal-setting/appearance')

    const darkMode = view.getByText('Dark')
    const lightMode = view.getByText('Light')
    const syncWithComputer = view.getByText('Sync with computer')

    await view.events.click(darkMode)
    expect(view.getByLabelText('Dark')).toBeChecked()
    const calls = await waitForAccountAppearanceMutationCalls()
    expect(calls.at(-1)?.variables).toEqual({ theme: 'dark' })
    expect(window.matchMedia('(prefers-color-scheme: light)').matches).toBe(
      false,
    )

    await view.events.click(lightMode)
    await vi.waitUntil(() => calls.length === 2)
    expect(calls.at(-1)?.variables).toEqual({ theme: 'light' })
    expect(window.matchMedia('(prefers-color-scheme: dark)').matches).toBe(
      false,
    )

    await view.events.click(syncWithComputer)
    expect(view.getByLabelText('Sync with computer')).toBeChecked()
  })
})
