// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTemplateRef } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { getKeyboardShortcutCombinations } from '#shared/composables/useKeyboardShortcut/keyboardShortcutCatalogue.ts'
import { KEYBOARD_SHORTCUTS_STORAGE_KEY } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcutsEnabled.ts'

import TableRow from '#desktop/components/CommonTable/TableRow.vue'
import { useTableRowNavigation } from '#desktop/components/CommonTable/useTableRowNavigation.ts'
import { useListKeyboardNavigation } from '#desktop/composables/useListKeyboardNavigation.ts'

const EVENT_KEYS: Record<string, string> = {
  arrowup: 'ArrowUp',
  arrowdown: 'ArrowDown',
  arrowleft: 'ArrowLeft',
  arrowright: 'ArrowRight',
  enter: 'Enter',
}

const eventKey = (combination: string) => {
  const key = EVENT_KEYS[combination]
  if (!key) throw new Error(`No key for the combination "${combination}"`)

  return key
}

const renderList = () => {
  const onLeave = vi.fn((_key: string) => true)
  const onClickRow = vi.fn()

  const wrapper = renderComponent(
    {
      components: { TableRow },
      template: `
        <div ref="list">
          <table>
            <tbody ref="rows">
              <TableRow
                v-for="item in items"
                :key="item.id"
                :item="item"
                @click-row="onClickRow"
              >
                <td>{{ item.id }}</td>
              </TableRow>
            </tbody>
          </table>
        </div>
      `,
      setup: () => {
        useTableRowNavigation(useTemplateRef<HTMLElement>('rows'), () => false)
        useListKeyboardNavigation({ list: useTemplateRef<HTMLElement>('list'), onLeave })

        return { items: [{ id: 'first' }, { id: 'second' }, { id: 'third' }], onClickRow }
      },
    },
    { router: true },
  )

  return { wrapper, rows: wrapper.getAllByTestId('table-row'), onLeave, onClickRow }
}

describe('keyboard shortcut catalogue of the lists', () => {
  beforeEach(() => {
    // The list keys are no shortcuts of the registry, so they work with the switch turned off.
    localStorage.setItem(KEYBOARD_SHORTCUTS_STORAGE_KEY, 'false')
  })

  afterEach(() => {
    localStorage.removeItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)
  })

  it('moves over the rows with the keys of the catalogue', async () => {
    const { wrapper, rows } = renderList()

    const keys = getKeyboardShortcutCombinations('list-move-up-down').map(eventKey)

    const pressOnMiddleRow = async (key: string) => {
      rows[1].focus()
      await wrapper.events.keyboard(`{${key}}`)

      return document.activeElement
    }

    expect(keys).toHaveLength(2)

    const [moveUp, moveDown] = keys

    expect(await pressOnMiddleRow(moveUp)).toBe(rows[0])
    expect(await pressOnMiddleRow(moveDown)).toBe(rows[2])
  })

  it.each(getKeyboardShortcutCombinations('list-move-up-down'))(
    'enters the list with %s of the catalogue',
    async (combination) => {
      const { wrapper, rows } = renderList()

      await wrapper.events.keyboard(`{${eventKey(combination)}}`)

      expect(rows).toContain(document.activeElement)
    },
  )

  it('hands the keys of the catalogue that leave a row to the page', async () => {
    const { wrapper, rows, onLeave } = renderList()

    const keys = getKeyboardShortcutCombinations('list-move-left-right').map(eventKey)

    rows[1].focus()
    await wrapper.events.keyboard(keys.map((key) => `{${key}}`).join(''))

    expect(keys).toHaveLength(2)
    expect(onLeave.mock.calls.map(([key]) => key)).toEqual(keys)
  })

  it('selects a row with the key of the catalogue', async () => {
    const { wrapper, rows, onClickRow } = renderList()

    const keys = getKeyboardShortcutCombinations('list-select-item').map(eventKey)

    rows[1].focus()
    await wrapper.events.keyboard(keys.map((key) => `{${key}}`).join(''))

    expect(keys).toHaveLength(1)
    expect(onClickRow).toHaveBeenCalledExactlyOnceWith({ id: 'second' })
  })
})
