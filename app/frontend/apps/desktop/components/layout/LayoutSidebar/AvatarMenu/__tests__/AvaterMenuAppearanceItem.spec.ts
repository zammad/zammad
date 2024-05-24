// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumAppearanceTheme } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import AvatarMenuAppearanceItem from '../AvatarMenuAppearanceItem.vue'

describe('avatar menu appearance item', () => {
  it('renders menu item with switcher', async () => {
    mockUserCurrent({
      lastname: 'Doe',
      firstname: 'John',
      preferences: {
        theme: EnumAppearanceTheme.Dark,
      },
    })

    const view = renderComponent(AvatarMenuAppearanceItem, {
      props: {
        label: 'Appearance',
      },
    })

    expect(view.getByText('Appearance')).toBeInTheDocument()
    const appearanceSwitch = view.getByRole('checkbox', { name: 'Dark Mode' })

    expect(appearanceSwitch).toBeChecked()

    await view.events.click(appearanceSwitch)

    expect(appearanceSwitch).not.toBeChecked()

    const session = useSessionStore()

    expect(session.user?.preferences?.theme).toBe(EnumAppearanceTheme.Light)
  })
})
