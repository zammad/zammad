// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { initializeKeyboardShortcutsDialog } from '#desktop/components/KeyboardShortcutsDialog/useKeyboardShortcutsDialog.ts'

import AvatarMenu from '../../AvatarMenu.vue'

const renderAvatarMenu = async (permissions: string[]) => {
  mockUserCurrent({ firstname: 'John', lastname: 'Doe' })
  mockPermissions(permissions)
  useAuthenticationStore().authenticated = true

  const view = renderComponent(
    {
      components: { AvatarMenu },
      template: '<AvatarMenu />',
      setup: () => {
        initializeKeyboardShortcutsDialog()
      },
    },
    {
      dialog: true,
      form: true,
      router: true,
      store: true,
    },
  )

  await view.events.click(view.getByRole('button', { name: 'User menu' }))

  // The entries render with the popover.
  await view.findByRole('menuitem', { name: 'Sign out' })

  return view
}

describe('avatar menu keyboard-shortcuts plugin', () => {
  it.each([['ticket.agent'], ['admin.user'], ['ticket.customer']])(
    'is shown with the permission %s',
    async (name) => {
      const view = await renderAvatarMenu([name])

      expect(view.getByRole('menuitem', { name: 'Keyboard shortcuts' })).toBeInTheDocument()
    },
  )

  it('opens the keyboard shortcuts dialog', async () => {
    const view = await renderAvatarMenu(['ticket.agent'])

    await view.events.click(view.getByRole('button', { name: 'Keyboard shortcuts' }))

    expect(
      await view.findByRole('heading', { level: 3, name: 'Keyboard shortcuts' }),
    ).toBeInTheDocument()
    expect(view.getByRole('switch', { name: 'Enable keyboard shortcuts' })).toBeInTheDocument()
  })

  it('opens the dialog only once', async () => {
    const view = await renderAvatarMenu(['ticket.agent'])

    await view.events.click(view.getByRole('button', { name: 'Keyboard shortcuts' }))
    await view.findByRole('heading', { level: 3, name: 'Keyboard shortcuts' })

    await view.events.click(view.getByRole('button', { name: 'User menu' }))
    await view.events.click(await view.findByRole('button', { name: 'Keyboard shortcuts' }))

    expect(view.getAllByRole('switch', { name: 'Enable keyboard shortcuts' })).toHaveLength(1)
  })

  it('closes the dialog when the session ends', async () => {
    const view = await renderAvatarMenu(['ticket.agent'])

    await view.events.click(view.getByRole('button', { name: 'Keyboard shortcuts' }))
    await view.findByRole('heading', { level: 3, name: 'Keyboard shortcuts' })

    useAuthenticationStore().authenticated = false

    await waitFor(() =>
      expect(
        view.queryByRole('heading', { level: 3, name: 'Keyboard shortcuts' }),
      ).not.toBeInTheDocument(),
    )
  })
})
