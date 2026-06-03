// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { createPinia, setActivePinia } from 'pinia'
import { defineComponent, nextTick, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketUpdateBulkMutation,
  waitForTicketUpdateBulkMutationCalls,
} from '#desktop/entities/ticket/graphql/mutations/updateBulk.mocks.ts'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import { useDragAndDropBulk } from '../useDragAndDropBulk.ts'

import type { DragAndDropBulkArgs, DragAndDropBulkOptions } from '../types.ts'

// We try to simulate the table action as in an integration test
const triggerDragAndDrop = async ({
  rowItemId,
  target,
  checkboxDisabled = false,
}: {
  rowItemId: string
  target: HTMLElement
  checkboxDisabled?: boolean
}) => {
  const row = document.createElement('tr')
  row.dataset.itemId = rowItemId

  const checkbox = document.createElement('div')
  checkbox.setAttribute('role', 'checkbox')
  checkbox.setAttribute('aria-disabled', String(checkboxDisabled))
  row.appendChild(checkbox)

  const rowInner = document.createElement('td')
  row.appendChild(rowInner)

  document.body.appendChild(row)
  document.body.appendChild(target)

  rowInner.dispatchEvent(
    new MouseEvent('mousedown', {
      bubbles: true,
      button: 0,
      clientX: 10,
      clientY: 10,
    }),
  )

  document.dispatchEvent(
    new MouseEvent('mousemove', {
      bubbles: true,
      clientX: 30,
      clientY: 30,
    }),
  )

  await vi.advanceTimersByTimeAsync(250)

  const targetInner = document.createElement('span')
  target.appendChild(targetInner)

  targetInner.dispatchEvent(
    new MouseEvent('mouseup', {
      bubbles: true,
    }),
  )

  row.remove()
  target.remove()
}

const renderDragAndDropBulk = (args: DragAndDropBulkArgs, options?: DragAndDropBulkOptions) => {
  let composable!: ReturnType<typeof useDragAndDropBulk>

  const ChildComponent = defineComponent({
    setup() {
      composable = useDragAndDropBulk(args, options)

      return () => 'Child Component'
    },
  })

  renderComponent({
    components: { ChildComponent },

    template: `
      <KeepAlive>
        <ChildComponent />
      </KeepAlive>
    `,
    setup() {},
  })

  return composable
}

describe('useDragAndDropBulk', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
    document.body.innerHTML = ''
  })

  it('calls ticket bulk update mutation when dropping on a macro target', async () => {
    const ticketInternalId = '1'
    const macroInternalId = '2'

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 1,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })

    renderDragAndDropBulk({
      checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', ticketInternalId)])),
      bulkSelector: ref({ entityIds: [convertToGraphQLId('Ticket', ticketInternalId)] }),
    })

    const macroTarget = document.createElement('li')
    macroTarget.dataset.internalId = macroInternalId
    macroTarget.dataset.type = 'macro'

    await triggerDragAndDrop({ rowItemId: ticketInternalId, target: macroTarget })

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      selector: {
        entityIds: [convertToGraphQLId('Ticket', ticketInternalId)],
      },
      perform: {
        macroId: convertToGraphQLId('Macro', macroInternalId),
      },
    })
  })

  it('uses overview id selector when bulk count and overview context are present', async () => {
    const ticketInternalId = '1'
    const macroInternalId = '2'
    const overviewId = convertToGraphQLId('Overview', 1)

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 1,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })
    renderDragAndDropBulk({
      checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', ticketInternalId)])),
      bulkSelector: ref({ overviewId }),
    })

    const macroTarget = document.createElement('li')
    macroTarget.dataset.internalId = macroInternalId
    macroTarget.dataset.type = 'macro'

    await triggerDragAndDrop({ rowItemId: ticketInternalId, target: macroTarget })

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      selector: {
        overviewId,
      },
      perform: {
        macroId: convertToGraphQLId('Macro', macroInternalId),
      },
    })
  })

  it('does not start drag when the row checkbox is disabled (no write permission)', async () => {
    const ticketInternalId = '1'
    const macroInternalId = '3'

    const useDragAndDropBulk = renderDragAndDropBulk({
      checkedTicketIds: ref(new Set<ID>()),
      bulkSelector: ref({}),
    })

    const macroTarget = document.createElement('li')
    macroTarget.dataset.internalId = macroInternalId
    macroTarget.dataset.type = 'macro'

    await triggerDragAndDrop({
      rowItemId: ticketInternalId,
      target: macroTarget,
      checkboxDisabled: true,
    })

    expect(useDragAndDropBulk.isActive.value).toBe(false)
  })

  it('uses search query selector when bulk count and search context are present', async () => {
    const ticketInternalId = '1'
    const macroInternalId = '3'

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 1,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })

    renderDragAndDropBulk({
      checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', ticketInternalId)])),
      bulkSelector: ref({ searchQuery: 'state:new' }),
    })

    const macroTarget = document.createElement('li')
    macroTarget.dataset.internalId = macroInternalId
    macroTarget.dataset.type = 'macro'

    await triggerDragAndDrop({ rowItemId: ticketInternalId, target: macroTarget })

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      selector: {
        searchQuery: 'state:new',
      },
      perform: {
        macroId: convertToGraphQLId('Macro', macroInternalId),
      },
    })
  })

  it('skips activation if touch device', () => {
    vi.doMock('#shared/composables/useTouchDevice.ts', () => ({
      useTouchDevice: () => ({
        isTouchDevice: ref(true),
      }),
    }))

    const { isActive } = renderDragAndDropBulk({
      checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', 1)])),
      bulkSelector: ref({ searchQuery: 'state:new' }),
    })

    expect(isActive.value).toBe(false)

    vi.clearAllMocks()
  })

  it('triggers confirmation when selected count is greater than threshold', async () => {
    vi.useFakeTimers()

    const ticketInternalId = '1'
    const macroInternalId = '2'

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 1,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })

    renderDragAndDropBulk({
      checkedTicketIds: ref(
        new Set(Array.from({ length: 20 }, (_, i) => convertToGraphQLId('Ticket', i + 1))),
      ),
      bulkSelector: ref({ entityIds: [convertToGraphQLId('Ticket', ticketInternalId)] }),
    })

    const store = useTicketBulkUpdateStore()
    const spy = vi.spyOn(store, 'requestBulkConfirmation')

    const macroTarget = document.createElement('li')
    macroTarget.dataset.internalId = macroInternalId
    macroTarget.dataset.type = 'macro'

    await triggerDragAndDrop({ rowItemId: ticketInternalId, target: macroTarget })

    await vi.runAllTimersAsync()

    expect(spy).toHaveBeenCalledWith('macro', expect.objectContaining({ resolveImmediate: false }))
    vi.useRealTimers()
  })

  it('does not activate drag and drop when disabled via option', async () => {
    const ticketInternalId = '1'
    const macroInternalId = '2'
    const store = useTicketBulkUpdateStore()
    const confirmationSpy = vi.spyOn(store, 'requestBulkConfirmation')

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 1,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })

    const dragAndDrop = renderDragAndDropBulk(
      {
        checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', ticketInternalId)])),
        bulkSelector: ref({ entityIds: [convertToGraphQLId('Ticket', ticketInternalId)] }),
      },
      { enabled: false },
    )

    const macroTarget = document.createElement('li')
    macroTarget.dataset.internalId = macroInternalId
    macroTarget.dataset.type = 'macro'

    await triggerDragAndDrop({ rowItemId: ticketInternalId, target: macroTarget })

    expect(dragAndDrop.isActive.value).toBe(false)
    expect(confirmationSpy).not.toHaveBeenCalled()
  })

  it('reactivates drag and drop when enabled option switches to true', async () => {
    const ticketInternalId = '1'
    const macroInternalId = '2'
    const enabled = ref(false)
    const store = useTicketBulkUpdateStore()
    const confirmationSpy = vi.spyOn(store, 'requestBulkConfirmation')

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 1,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })

    renderDragAndDropBulk(
      {
        checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', ticketInternalId)])),
        bulkSelector: ref({ entityIds: [convertToGraphQLId('Ticket', ticketInternalId)] }),
      },
      { enabled },
    )

    const macroTarget = document.createElement('li')
    macroTarget.dataset.internalId = macroInternalId
    macroTarget.dataset.type = 'macro'

    await triggerDragAndDrop({ rowItemId: ticketInternalId, target: macroTarget })
    expect(confirmationSpy).not.toHaveBeenCalled()

    enabled.value = true
    await nextTick()

    await triggerDragAndDrop({ rowItemId: ticketInternalId, target: macroTarget })
    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls).toHaveLength(1)

    expect(calls.at(-1)?.variables).toEqual({
      selector: {
        entityIds: [convertToGraphQLId('Ticket', ticketInternalId)],
      },
      perform: {
        macroId: convertToGraphQLId('Macro', macroInternalId),
      },
    })
  })

  it('cancels drag and drop on Escape key press', async () => {
    const ticketInternalId = '1'

    const { isActive } = renderDragAndDropBulk({
      checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', ticketInternalId)])),
      bulkSelector: ref({ searchQuery: 'state:new' }),
    })

    const row = document.createElement('tr')
    row.dataset.itemId = ticketInternalId

    const rowInner = document.createElement('td')
    row.appendChild(rowInner)

    document.body.appendChild(row)

    rowInner.dispatchEvent(
      new MouseEvent('mousedown', {
        bubbles: true,
        button: 0,
        clientX: 10,
        clientY: 10,
      }),
    )

    document.dispatchEvent(
      new MouseEvent('mousemove', {
        bubbles: true,
        clientX: 30,
        clientY: 30,
      }),
    )

    await vi.advanceTimersByTimeAsync(250)

    expect(isActive.value).toBe(true)

    document.dispatchEvent(
      new KeyboardEvent('keydown', {
        key: 'Escape',
        bubbles: true,
      }),
    )

    expect(isActive.value).toBe(false)

    row.remove()
  })

  // Regression: link cells (CommonLink) attach `@keydown.stop`, which stops
  // the keystroke during bubbling. The Escape listener must run in the capture
  // phase so it still fires when the drag was started from such a cell.
  it('cancels drag and drop on Escape even when a focused cell stops propagation', async () => {
    const ticketInternalId = '1'

    const { isActive } = renderDragAndDropBulk({
      checkedTicketIds: ref(new Set([convertToGraphQLId('Ticket', ticketInternalId)])),
      bulkSelector: ref({ searchQuery: 'state:new' }),
    })

    const row = document.createElement('tr')
    row.dataset.itemId = ticketInternalId

    const rowInner = document.createElement('td')
    // Simulate a link cell that stops keydown propagation during bubbling.
    const link = document.createElement('a')
    link.addEventListener('keydown', (event) => event.stopPropagation())
    rowInner.appendChild(link)
    row.appendChild(rowInner)

    document.body.appendChild(row)

    rowInner.dispatchEvent(
      new MouseEvent('mousedown', {
        bubbles: true,
        button: 0,
        clientX: 10,
        clientY: 10,
      }),
    )

    document.dispatchEvent(
      new MouseEvent('mousemove', {
        bubbles: true,
        clientX: 30,
        clientY: 30,
      }),
    )

    await vi.advanceTimersByTimeAsync(250)

    expect(isActive.value).toBe(true)

    link.dispatchEvent(
      new KeyboardEvent('keydown', {
        key: 'Escape',
        bubbles: true,
      }),
    )

    expect(isActive.value).toBe(false)

    row.remove()
  })
})
