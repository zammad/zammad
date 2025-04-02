// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import {
  fireEvent,
  getAllByRole,
  getByLabelText,
  getByRole,
} from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { mockLogoutMutation } from '#shared/graphql/mutations/logout.mocks.ts'

describe('Left sidebar', () => {
  beforeEach(() => {
    mockUserCurrent({
      id: 'gid://zammad/User/999',
      firstname: 'Nicole',
      lastname: 'Braun',
      fullname: 'Nicole Braun',
      preferences: {},
    })
  })

  afterEach(() => {
    localStorage.clear()
  })

  describe('width handling', () => {
    it('renders initially with the default width', async () => {
      const view = await visitView('/')

      const aside = view.getByRole('complementary')

      expect(aside.parentElement).toHaveStyle({
        gridTemplateColumns: '260px 1fr',
      })
    })

    it('restores stored width', async () => {
      localStorage.setItem('gid://zammad/User/999-left-sidebar-width', '216')

      const view = await visitView('/')

      const aside = view.getByRole('complementary')

      expect(aside.parentElement).toHaveStyle({
        gridTemplateColumns: '216px 1fr',
      })
    })

    it('supports collapsing/expanding', async () => {
      const view = await visitView('/')

      const aside = view.getByRole('complementary')
      const collapseButton = getByRole(aside, 'button', {
        name: 'Collapse sidebar',
      })

      await view.events.click(collapseButton)

      expect(aside.parentElement).toHaveStyle({
        gridTemplateColumns: '56px 1fr',
      })

      const expandButton = getByRole(aside, 'button', {
        name: 'Expand sidebar',
      })

      await view.events.click(expandButton)

      expect(aside.parentElement).toHaveStyle({
        gridTemplateColumns: '260px 1fr',
      })
    })

    it('restores collapsed state width', async () => {
      localStorage.setItem(
        'gid://zammad/User/999-left-sidebar-collapsed',
        'true',
      )

      const view = await visitView('/')

      const aside = view.getByRole('complementary')

      expect(aside.parentElement).toHaveStyle({
        gridTemplateColumns: '56px 1fr',
      })
    })

    it('supports resizing', async () => {
      const view = await visitView('/')

      const aside = view.getByRole('complementary')
      const resizeHandle = getByLabelText(aside, 'Resize sidebar')

      await fireEvent.mouseDown(resizeHandle, { clientX: 260 })
      await fireEvent.mouseMove(document, { clientX: 216 })
      await fireEvent.mouseUp(document, { clientX: 216 })

      expect(aside.parentElement).toHaveStyle({
        gridTemplateColumns: '216px 1fr',
      })
    })

    it('supports resetting', async () => {
      localStorage.setItem('gid://zammad/User/999-left-sidebar-width', '216')

      const view = await visitView('/')

      const aside = view.getByRole('complementary')
      const resizeHandle = getByLabelText(aside, 'Resize sidebar')

      await view.events.dblClick(resizeHandle)

      expect(aside.parentElement).toHaveStyle({
        gridTemplateColumns: '260px 1fr',
      })
    })
  })

  describe('User menu', () => {
    afterEach(() => {
      vi.clearAllMocks()
    })

    it.each([{ collapsed: false }, { collapsed: true }])(
      'shows menu popover on click (collapsed: $collapsed)',
      async ({ collapsed }) => {
        localStorage.setItem(
          'gid://zammad/User/999-left-sidebar-collapsed',
          String(collapsed),
        )

        const view = await visitView('/')

        const aside = view.getByRole('complementary')
        const avatarButton = getByRole(aside, 'button', {
          name: 'Nicole Braun',
        })

        expect(avatarButton).toHaveTextContent('NB')

        await view.events.click(avatarButton)

        const popover = view.getByRole('region', { name: 'Nicole Braun' })

        expect(popover).toHaveTextContent('Nicole Braun')

        const menu = getByRole(popover, 'menu')
        const menuItems = getAllByRole(menu, 'menuitem')

        expect(menuItems).toHaveLength(4)
      },
    )

    it('supports cycling appearance state', async () => {
      mockPermissions(['user_preferences.appearance'])

      const view = await visitView('/')

      const aside = view.getByRole('complementary')
      const avatarButton = getByRole(aside, 'button', { name: 'Nicole Braun' })

      await view.events.click(avatarButton)

      const appearanceButton = view.getByRole('button', { name: 'Appearance' })
      const appearanceSwitch = view.getByRole('checkbox', { name: 'Dark Mode' })

      expect(appearanceSwitch).toBePartiallyChecked()

      await view.events.click(appearanceSwitch)

      expect(appearanceSwitch).toBeChecked()

      await view.events.click(appearanceButton)

      expect(appearanceSwitch).not.toBeChecked()

      await view.events.click(appearanceSwitch)

      expect(appearanceSwitch).toBePartiallyChecked()
    })

    it('supports navigating to playground', async () => {
      const view = await visitView('/')

      const aside = view.getByRole('complementary')
      const avatarButton = getByRole(aside, 'button', { name: 'Nicole Braun' })

      await view.events.click(avatarButton)

      const playgroundLink = view.getByRole('link', {
        name: 'Playground',
      })

      await view.events.click(playgroundLink)

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to playground page').toHaveCurrentUrl(
          '/playground',
        )
      })

      expect(
        view.queryByRole('region', { name: 'User menu' }),
      ).not.toBeInTheDocument()
    })

    // TODO: Cover keyboard shortcuts menu item when ready.

    it('supports navigating to personal settings', async () => {
      const view = await visitView('/')

      const aside = view.getByRole('complementary')
      const avatarButton = getByRole(aside, 'button', { name: 'Nicole Braun' })

      await view.events.click(avatarButton)

      const personalSettingsLink = view.getByRole('link', {
        name: 'Profile settings',
      })

      await view.events.click(personalSettingsLink)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to personal settings page',
        ).toHaveCurrentUrl('/personal-setting/appearance')
      })

      expect(
        view.queryByRole('region', { name: 'User menu' }),
      ).not.toBeInTheDocument()
    })

    it('supports signing out', async () => {
      const view = await visitView('/')

      const aside = view.getByRole('complementary')
      const avatarButton = getByRole(aside, 'button', { name: 'Nicole Braun' })

      await view.events.click(avatarButton)

      const logoutLink = view.getByRole('link', { name: 'Sign out' })

      mockLogoutMutation({
        logout: {
          success: true,
          externalLogoutUrl: null,
        },
      })

      await view.events.click(logoutLink)

      await flushPromises()

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to login page').toHaveCurrentUrl(
          '/login',
        )
      })

      expect(
        view.queryByRole('region', { name: 'User menu' }),
      ).not.toBeInTheDocument()
    })
  })
})
