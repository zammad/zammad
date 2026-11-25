// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockMediaTheme } from '#tests/support/mock-mediaTheme.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { useKeyboardShortcutsEnabled } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcutsEnabled.ts'
import { EnumAppearanceTheme } from '#shared/graphql/types.ts'
import emitter from '#shared/utils/emitter.ts'

import { closeDialog, isDialogOpened } from '#desktop/components/CommonDialog/useDialog.ts'
import {
  initializeKeyboardShortcutsDialog,
  KEYBOARD_SHORTCUTS_DIALOG_NAME,
} from '#desktop/components/KeyboardShortcutsDialog/useKeyboardShortcutsDialog.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'
import { UserCurrentAppearanceDocument } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentAppearance.api.ts'
import { mockUserCurrentAppearanceMutation } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentAppearance.mocks.ts'
import { useThemeStore } from '#desktop/stores/theme.ts'

import { useLayoutShortcuts } from '../useLayoutShortcuts.ts'

import type { RouteRecordRaw } from 'vue-router'

const view = { template: '<div />' }

const routes: RouteRecordRaw[] = [
  { path: '/', name: 'Home', component: view },
  { path: '/dashboard', name: 'Dashboard', component: view },
  { path: '/tickets/view', name: 'TicketOverview', component: view },
  { path: '/tickets/create', name: 'TicketCreate', component: view },
  { path: '/logout', name: 'Logout', component: view },
  { path: '/elsewhere', name: 'Elsewhere', component: view },
]

const renderShortcuts = async () => {
  const wrapper = renderComponent(
    {
      template: '<input aria-label="Field" />',
      setup: () => {
        initializeKeyboardShortcutsDialog()
        useLayoutShortcuts()
      },
    },
    { dialog: true, form: true, router: true, routerRoutes: routes, store: true },
  )

  await getTestRouter().push('/elsewhere')

  return wrapper
}

describe('useLayoutShortcuts', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ customer_ticket_create: false, dashboard: true })
  })

  it.each<[string, `/${string}`]>([
    ['h', '/dashboard'],
    ['o', '/tickets/view'],
    ['n', '/tickets/create'],
    ['{Shift>}L{/Shift}', '/logout'],
  ])('navigates with %s to %s', async (keys, expectedUrl) => {
    const wrapper = await renderShortcuts()

    await wrapper.events.keyboard(keys)

    await waitFor(() => expect(wrapper).toHaveCurrentUrl(expectedUrl))
  })

  it('goes to the root path with h while there is no dashboard route', async () => {
    const wrapper = await renderShortcuts()

    // Production builds do not register the dashboard route yet.
    vi.spyOn(getTestRouter(), 'hasRoute').mockReturnValueOnce(false)

    await wrapper.events.keyboard('h')

    await waitFor(() => expect(wrapper).toHaveCurrentUrl('/'))
  })

  it('does nothing with h while the dashboard is turned off', async () => {
    mockApplicationConfig({ dashboard: false })

    const wrapper = await renderShortcuts()

    await wrapper.events.keyboard('h')

    expect(wrapper).toHaveCurrentUrl('/elsewhere')
  })

  it('does not navigate while typing in a field', async () => {
    const wrapper = await renderShortcuts()

    await wrapper.events.type(wrapper.getByLabelText('Field'), 'o')

    expect(wrapper.getByLabelText('Field')).toHaveValue('o')
    expect(wrapper).toHaveCurrentUrl('/elsewhere')
  })

  it('expands the collapsed sidebar and focuses the quick search with s', async () => {
    const { isSidebarCollapsed, toggleSidebar } = useSidebarDisplay(SidebarName.Primary)
    toggleSidebar(true)

    const focusHandler = vi.fn()
    emitter.on('focus-quick-search-field', focusHandler)

    const wrapper = await renderShortcuts()

    await wrapper.events.keyboard('s')

    expect(isSidebarCollapsed.value).toBe(false)
    await waitFor(() => expect(focusHandler).toHaveBeenCalledOnce())

    emitter.off('focus-quick-search-field', focusHandler)
  })

  it('does not go to the overviews without access to them', async () => {
    mockPermissions(['admin'])

    const wrapper = await renderShortcuts()

    await wrapper.events.keyboard('o')

    expect(wrapper).toHaveCurrentUrl('/elsewhere')
  })

  describe('cheat sheet', () => {
    const findCheatSheet = (wrapper: Awaited<ReturnType<typeof renderShortcuts>>) =>
      wrapper.findByRole('heading', { level: 3, name: 'Keyboard shortcuts' })

    afterEach(async () => {
      useKeyboardShortcutsEnabled().isEnabled.value = true
      await closeDialog(KEYBOARD_SHORTCUTS_DIALOG_NAME, true)
    })

    it('opens with ? and closes with a second ?', async () => {
      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('?')
      expect(await findCheatSheet(wrapper)).toBeInTheDocument()

      await wrapper.events.keyboard('?')
      await waitFor(() =>
        expect(
          wrapper.queryByRole('heading', { level: 3, name: 'Keyboard shortcuts' }),
        ).not.toBeInTheDocument(),
      )
    })

    it('does not open while typing in a field', async () => {
      const wrapper = await renderShortcuts()

      await wrapper.events.type(wrapper.getByLabelText('Field'), '?')

      expect(wrapper.getByLabelText('Field')).toHaveValue('?')
      expect(isDialogOpened(KEYBOARD_SHORTCUTS_DIALOG_NAME)).toBe(false)
    })

    it('does not open while shortcuts are turned off', async () => {
      useKeyboardShortcutsEnabled().isEnabled.value = false

      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('?')

      expect(isDialogOpened(KEYBOARD_SHORTCUTS_DIALOG_NAME)).toBe(false)
    })

    it('opens for customers', async () => {
      mockPermissions(['ticket.customer'])

      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('?')

      expect(await findCheatSheet(wrapper)).toBeInTheDocument()
    })
  })

  describe('appearance', () => {
    beforeEach(() => {
      mockMediaTheme(EnumAppearanceTheme.Light)
      mockUserCurrentAppearanceMutation({ userCurrentAppearance: { success: true } })
    })

    it('switches the appearance with d', async () => {
      mockPermissions(['ticket.agent', 'user_preferences.appearance'])

      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('d')

      await waitFor(() => expect(useThemeStore().currentTheme).toBe(EnumAppearanceTheme.Dark))
    })

    it('does not switch the appearance without the permission', async () => {
      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('d')

      expect(getGraphQLMockCalls(UserCurrentAppearanceDocument)).toHaveLength(0)
    })
  })

  describe('for customers', () => {
    beforeEach(() => {
      mockPermissions(['ticket.customer'])
    })

    it('does not open a new ticket while customers may not create tickets', async () => {
      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('n')

      expect(wrapper).toHaveCurrentUrl('/elsewhere')
    })

    it('opens a new ticket while customers may create tickets', async () => {
      mockApplicationConfig({ customer_ticket_create: true })

      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('n')

      await waitFor(() => expect(wrapper).toHaveCurrentUrl('/tickets/create'))
    })

    it('does not go to the dashboard with h', async () => {
      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('h')

      expect(wrapper).toHaveCurrentUrl('/elsewhere')
    })

    it('navigates with o to the overviews', async () => {
      const wrapper = await renderShortcuts()

      await wrapper.events.keyboard('o')

      await waitFor(() => expect(wrapper).toHaveCurrentUrl('/tickets/view'))
    })
  })
})
