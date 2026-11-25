// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTemplateRef } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'

import {
  getOverlayContainerMeta,
  getRouteIdentifier,
} from '#desktop/composables/useOverlayContainer.ts'

import { useListKeyboardNavigation } from '../useListKeyboardNavigation.ts'

const renderList = (onLeave = vi.fn((_key: string) => true)) => {
  const wrapper = renderComponent(
    {
      template: `
      <div ref="list">
        <table>
          <tbody>
            <tr data-item-id="1" tabindex="-1"><td>First</td></tr>
            <tr data-item-id="2" tabindex="-1"><td>Second</td></tr>
          </tbody>
        </table>
      </div>
    `,
      setup: () => {
        useListKeyboardNavigation({ list: useTemplateRef('list'), onLeave })
      },
    },
    { router: true },
  )

  return { wrapper, rows: wrapper.getAllByRole('row'), onLeave }
}

describe('useListKeyboardNavigation', () => {
  const { opened: openedDialogs, options: dialogOptions } = getOverlayContainerMeta('dialog')

  const pageIdentifier = () => getRouteIdentifier(getTestRouter().currentRoute.value)

  afterEach(() => {
    openedDialogs.value.clear()
    dialogOptions.clear()
  })

  it('enters the list with the arrow keys while nothing has the focus', async () => {
    const { wrapper, rows } = renderList()

    await wrapper.events.keyboard('{ArrowDown}')

    expect(rows[0]).toHaveFocus()
  })

  it.each([
    ['of the page', () => `some-dialog_${pageIdentifier()}`],
    ['shown globally', () => 'global-dialog'],
  ])('does not enter the list while a dialog %s is open', async (_, dialogName) => {
    const { wrapper, rows } = renderList()

    await getTestRouter().isReady()

    dialogOptions.set('global-dialog', {
      name: 'global-dialog',
      component: vi.fn().mockResolvedValue({}),
      global: true,
    })
    openedDialogs.value.add(dialogName())

    await wrapper.events.keyboard('{ArrowDown}')

    expect(rows[0]).not.toHaveFocus()
  })

  it('enters the list while only a dialog of another page is open', async () => {
    const { wrapper, rows } = renderList()

    openedDialogs.value.add('some-dialog_TicketDetailView_42')

    await wrapper.events.keyboard('{ArrowDown}')

    expect(rows[0]).toHaveFocus()
  })

  it('hands the keys leaving a row to the page', async () => {
    const { wrapper, rows, onLeave } = renderList()

    rows[0].focus()
    await wrapper.events.keyboard('{ArrowLeft}{ArrowRight}{ArrowUp}')

    expect(onLeave.mock.calls.map(([key]) => key)).toEqual(['ArrowLeft', 'ArrowRight', 'ArrowUp'])
  })

  it('leaves a key with a modifier alone', async () => {
    const { wrapper, rows, onLeave } = renderList()

    const handled: boolean[] = []
    const recordKey = (event: KeyboardEvent) => {
      if (event.key === 'ArrowLeft') handled.push(event.defaultPrevented)
    }

    window.addEventListener('keydown', recordKey)

    rows[0].focus()
    await wrapper.events.keyboard('{Shift>}{ArrowLeft}{/Shift}')

    window.removeEventListener('keydown', recordKey)

    expect(onLeave).not.toHaveBeenCalled()
    expect(handled).toEqual([false])
  })

  it('hands the arrow keys to the page while the list has no rows', async () => {
    const onEmpty = vi.fn(() => true)

    const wrapper = renderComponent(
      {
        template: '<div ref="list"><p>Nothing here</p></div>',
        setup: () => {
          useListKeyboardNavigation({ list: useTemplateRef('list'), onEmpty })
        },
      },
      { router: true },
    )

    await wrapper.events.keyboard('{ArrowDown}')

    expect(onEmpty).toHaveBeenCalledOnce()
  })
})
