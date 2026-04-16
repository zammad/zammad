// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import DragAndDropBulkConfirmation from '../DragAndDropBulkConfirmation.vue'
import { DragAndDropBulkEntityType } from '../types.ts'

describe('DragAndDropBulkConfirmation', () => {
  it('shows the confirmation dialog', async () => {
    const wrapper = renderComponent(DragAndDropBulkConfirmation, { router: true })

    const store = useTicketBulkUpdateStore()

    // More than 20 tickets triggers the confirmation dialog
    store.requestBulkConfirmation(25, DragAndDropBulkEntityType.Macro)

    await nextTick()

    expect(wrapper.getByRole('dialog')).toBeInTheDocument()
    expect(wrapper.getByRole('heading', { name: 'Confirm bulk action' })).toBeVisible()
  })

  it('hides the top and bottom drawers while the dialog is open', async () => {
    const wrapper = renderComponent(DragAndDropBulkConfirmation, { router: true })
    const store = useTicketBulkUpdateStore()

    store.requestBulkConfirmation(25, DragAndDropBulkEntityType.Macro)

    await nextTick()

    // Label for the header and action button shared the same text
    // If 2 both would be visible, the test would fail
    expect(wrapper.queryAllByText('Run macro')).toHaveLength(1)
    expect(wrapper.queryByText('Assign tickets')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('progressbar')).not.toBeInTheDocument()
  })

  it('shows the correct message for a macro confirmation', async () => {
    const wrapper = renderComponent(DragAndDropBulkConfirmation, { router: true })
    const store = useTicketBulkUpdateStore()

    store.requestBulkConfirmation(25, DragAndDropBulkEntityType.Macro)

    await nextTick()

    // 0 because useTicketBulkEdit is not populated
    expect(
      wrapper.getByText('You’re about to apply a macro to 0 tickets. Do you want to continue?'),
    ).toBeInTheDocument()
  })

  it('confirms action when clicking on button', async () => {
    const wrapper = renderComponent(DragAndDropBulkConfirmation, { router: true })
    const store = useTicketBulkUpdateStore()

    store.requestBulkConfirmation(25, DragAndDropBulkEntityType.Macro)

    await nextTick()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Run macro' }))

    expect(store.currentActiveEntityType).toBe(null)
    expect(store.confirmationPending).toBe(false)
  })

  it('closes the dialog when clicking on button', async () => {
    const wrapper = renderComponent(DragAndDropBulkConfirmation, { router: true })
    const store = useTicketBulkUpdateStore()

    store.requestBulkConfirmation(25, DragAndDropBulkEntityType.Macro)

    await nextTick()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Cancel & go back' }))

    expect(store.currentActiveEntityType).toBe(null)
    expect(store.confirmationPending).toBe(false)

    store.requestBulkConfirmation(25, DragAndDropBulkEntityType.Macro)

    await wrapper.rerender({})

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Close dialog' }))

    expect(store.currentActiveEntityType).toBe(null)
    expect(store.confirmationPending).toBe(false)
  })
})
