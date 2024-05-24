// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumAppearanceTheme } from '#shared/graphql/types.ts'

import { waitForUserCurrentAppearanceMutationCalls } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentAppearance.mocks.ts'

describe('appearance page', () => {
  it('should have dark theme set', async () => {
    mockUserCurrent({
      preferences: {
        theme: EnumAppearanceTheme.Dark,
      },
    })

    const view = await visitView('/personal-setting/appearance')

    expect(view.getByRole('radio', { checked: true })).toHaveTextContent('dark')
  })

  it('should have light theme set', async () => {
    mockUserCurrent({
      preferences: {
        theme: EnumAppearanceTheme.Light,
      },
    })

    const view = await visitView('/personal-setting/appearance')

    expect(view.getByRole('radio', { checked: true })).toHaveTextContent(
      'light',
    )
  })

  it('update appearance to dark', async () => {
    mockUserCurrent({
      preferences: {
        theme: EnumAppearanceTheme.Light,
      },
    })
    const view = await visitView('/personal-setting/appearance')

    expect(view.getByLabelText('Light')).toBeChecked()

    const darkMode = view.getByText('Dark')
    const lightMode = view.getByText('Light')
    const syncWithComputer = view.getByText('Sync with computer')

    await view.events.click(darkMode)

    expect(view.getByLabelText('Dark')).toBeChecked()

    const calls = await waitForUserCurrentAppearanceMutationCalls()

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
