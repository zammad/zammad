// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { keyboardShortcutCatalogue } from '#shared/composables/useKeyboardShortcut/keyboardShortcutCatalogue.ts'
import { KEYBOARD_SHORTCUTS_STORAGE_KEY } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcutsEnabled.ts'
import { cleanupMarkup } from '#shared/utils/markup.ts'

import KeyboardShortcutsDialog from '../KeyboardShortcutsDialog.vue'

const { platform } = vi.hoisted(() => ({ platform: { isMac: false } }))

vi.mock('#shared/utils/browser.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/utils/browser.ts')>()),
  isMac: () => platform.isMac,
}))

const renderDialog = () =>
  renderComponent(KeyboardShortcutsDialog, {
    dialog: true,
    form: true,
    router: true,
  })

const ARROW_LABELS: Record<string, string> = {
  arrowup: '▲',
  arrowdown: '▼',
  arrowleft: '◀',
  arrowright: '▶',
}

const keysOfRow = (row: HTMLElement) =>
  Array.from(row.querySelectorAll('kbd')).map((key) => key.textContent)

describe('KeyboardShortcutsDialog.vue', () => {
  beforeEach(() => {
    platform.isMac = false
    localStorage.removeItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)
    mockApplicationConfig({ dashboard: true })
    mockPermissions(['ticket.agent', 'user_preferences.appearance'])
  })

  it('renders a content-only dialog with the switch on top', () => {
    const view = renderDialog()

    expect(view.getByRole('dialog')).toBeInTheDocument()
    expect(view.getByRole('heading', { level: 3, name: 'Keyboard shortcuts' })).toBeInTheDocument()
    expect(view.getByIconName('keyboard')).toBeInTheDocument()
    expect(view.getByRole('switch', { name: 'Enable keyboard shortcuts' })).toBeChecked()
    expect(view.getByRole('button', { name: 'Close dialog' })).toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'OK' })).not.toBeInTheDocument()
  })

  it('lists every shortcut of the catalogue in its group', () => {
    const view = renderDialog()

    keyboardShortcutCatalogue.forEach((group) => {
      const section = within(view.getByRole('region', { name: group.headline }))

      expect(section.getByRole('heading', { level: 4, name: group.headline })).toBeInTheDocument()

      group.subGroups.forEach((subGroup) => {
        const rows = within(section.getByRole('list', { name: subGroup.where })).getAllByRole(
          'listitem',
        )

        expect(rows).toHaveLength(subGroup.entries.length)

        subGroup.entries.forEach((entry, index) => {
          expect(rows[index]).toHaveTextContent(cleanupMarkup(entry.description))
          expect(keysOfRow(rows[index])).toEqual(
            entry.displayKeys.other.flat().map((key) => ARROW_LABELS[key] ?? key),
          )
        })
      })
    })
  })

  it('hides the dashboard shortcut while the dashboard is turned off', () => {
    mockApplicationConfig({ dashboard: false })

    const view = renderDialog()

    const navigation = within(view.getByRole('region', { name: 'Navigation' }))
    const rows = within(navigation.getByRole('list', { name: 'Used anywhere' })).getAllByRole(
      'listitem',
    )

    expect(view.queryByText('Dashboard')).not.toBeInTheDocument()
    expect(rows[0]).toHaveTextContent('Overviews')
  })

  it('lists only the shortcuts a customer can use', () => {
    mockPermissions(['ticket.customer', 'user_preferences.appearance'])

    const view = renderDialog()

    const agentOnly = [
      'Dashboard',
      'Notifications',
      'Open note box',
      'Reply to last article',
      'Set article to internal/public',
      'Inserts text module',
      'Inserts knowledge base answer',
      'Inserts a mention for a user',
    ]

    agentOnly.forEach((description) => {
      expect(view.queryByText(description)).not.toBeInTheDocument()
    })

    expect(view.getByText('Toggle dark mode')).toBeInTheDocument()
    expect(view.getByText('Overviews')).toBeInTheDocument()
    expect(view.getByText('Update as closed')).toBeInTheDocument()
    expect(view.getByText('bold')).toBeInTheDocument()
  })

  it('shows navigation and appearance in the first column, tickets and text editing in the second', () => {
    const view = renderDialog()

    const [firstColumn, secondColumn] = Array.from(
      view.getByTestId('keyboard-shortcuts-list').children,
    ) as HTMLElement[]

    const headlines = (column: HTMLElement) =>
      within(column)
        .getAllByRole('heading', { level: 4 })
        .map((headline) => headline.textContent?.trim())

    expect(headlines(firstColumn)).toEqual(['Navigation', 'Appearance'])
    expect(headlines(secondColumn)).toEqual(['Tickets', 'Text editing'])
  })

  it('drops the second column when it has no shortcut for the user', () => {
    mockPermissions(['admin.calendar', 'user_preferences.appearance'])

    const view = renderDialog()

    const list = view.getByTestId('keyboard-shortcuts-list')

    expect(list.children).toHaveLength(1)
    expect(
      within(list)
        .getAllByRole('heading', { level: 4 })
        .map((headline) => headline.textContent?.trim()),
    ).toEqual(['Navigation', 'Appearance'])
  })

  it.each([
    ['macOS', true, ['cmd', 'b'], ['ctrl', 'option', 'f']],
    ['the other operating systems', false, ['ctrl', 'b'], ['ctrl', 'shift', 'f']],
  ])('shows the keys of %s', (_, isMac, boldKeys, removeFormattingKeys) => {
    platform.isMac = isMac

    const view = renderDialog()

    const textEditing = within(view.getByRole('region', { name: 'Text editing' }))
    const rows = textEditing.getAllByRole('listitem')

    expect(keysOfRow(rows.find((row) => row.textContent?.includes('bold'))!)).toEqual(boldKeys)
    expect(
      keysOfRow(rows.find((row) => row.textContent?.includes('Removes the formatting'))!),
    ).toEqual(removeFormattingKeys)
  })

  it('draws the arrow keys as icons', () => {
    const view = renderDialog()

    const row = view.getByText('Move up and down').closest('li')!

    expect(getByIconName(row, 'caret-up-fill')).toBeInTheDocument()
    expect(getByIconName(row, 'caret-down-fill')).toBeInTheDocument()
    expect(keysOfRow(row)).toEqual(['▲', '▼'])
  })

  it('joins the steps of a sequence and renders the markup of a description', () => {
    const view = renderDialog()

    const sequence = view.getByText('…add object link URL').closest('li')!

    expect(keysOfRow(sequence)).toEqual(['.', '.', '.'])
    expect(within(sequence).getAllByText('then')).toHaveLength(2)

    expect(view.getByText('bold').tagName).toBe('B')
    expect(view.queryByText('Format as |bold|')).not.toBeInTheDocument()
  })

  it('turns the shortcuts off and on in the format of the old desktop view', async () => {
    const view = renderDialog()

    const shortcutSwitch = view.getByRole('switch', { name: 'Enable keyboard shortcuts' })

    await view.events.click(shortcutSwitch)

    expect(shortcutSwitch).not.toBeChecked()
    expect(localStorage.getItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)).toBe('false')

    await view.events.click(shortcutSwitch)

    expect(shortcutSwitch).toBeChecked()
    expect(localStorage.getItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)).toBeNull()
  })

  it('keeps the list and the switch usable while the shortcuts are off', async () => {
    const view = renderDialog()

    const list = view.getByTestId('keyboard-shortcuts-list')

    await view.events.click(view.getByRole('switch', { name: 'Enable keyboard shortcuts' }))

    expect(view.getByText('Dashboard')).toBeInTheDocument()
    expect(view.getByRole('switch', { name: 'Enable keyboard shortcuts' })).toBeEnabled()
    expect(list).not.toContainElement(
      view.getByRole('switch', { name: 'Enable keyboard shortcuts' }),
    )
  })
})
