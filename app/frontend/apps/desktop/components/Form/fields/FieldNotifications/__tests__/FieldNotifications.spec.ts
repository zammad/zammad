// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import {
  checkSimpleTableContent,
  checkSimpleTableHeader,
} from '#tests/support/components/checkSimpleTableContent.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

const tableHeaders = [
  'Name',
  'My tickets',
  'Not assigned',
  'Subscribed tickets',
  'All tickets',
  'Also notify via email',
]

const tableItems = [
  [
    'New ticket',
    'New ticket - My tickets',
    'New ticket - Not assigned',
    'New ticket - Subscribed tickets',
    'New ticket - All tickets',
    'New ticket - Also notify via email',
  ],
  [
    'Ticket update',
    'Ticket update - My tickets',
    'Ticket update - Not assigned',
    'Ticket update - Subscribed tickets',
    'Ticket update - All tickets',
    'Ticket update - Also notify via email',
  ],
  [
    'Ticket reminder reached',
    'Ticket reminder reached - My tickets',
    'Ticket reminder reached - Not assigned',
    'Ticket reminder reached - Subscribed tickets',
    'Ticket reminder reached - All tickets',
    'Ticket reminder reached - Also notify via email',
  ],
  [
    'Ticket escalation',
    'Ticket escalation - My tickets',
    'Ticket escalation - Not assigned',
    'Ticket escalation - Subscribed tickets',
    'Ticket escalation - All tickets',
    'Ticket escalation - Also notify via email',
  ],
]

const testValue = {
  create: {
    criteria: {
      ownedByMe: true,
      ownedByNobody: true,
      subscribed: true,
      no: false,
    },
    channel: { email: true, online: true },
  },
  update: {
    criteria: {
      ownedByMe: true,
      ownedByNobody: true,
      subscribed: true,
      no: false,
    },
    channel: { email: true, online: true },
  },
  reminderReached: {
    criteria: {
      ownedByMe: true,
      ownedByNobody: false,
      subscribed: false,
      no: false,
    },
    channel: { email: true, online: true },
  },
  escalation: {
    criteria: {
      ownedByMe: true,
      ownedByNobody: false,
      subscribed: false,
      no: false,
    },
    channel: { email: true, online: true },
  },
}

const wrapperParameters = {
  form: true,
  formField: true,
}

const renderNotificationsInput = async (
  props: Record<string, unknown> = {},
) => {
  const view = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      id: 'notifications',
      type: 'notifications',
      name: 'notifications',
      label: 'Notifications matrix',
      labelSrOnly: true,
      formId: 'form',
      ...props,
    },
    form: true,
  })

  await waitForNextTick(true)

  return view
}

describe('Form - Field - Notifications', () => {
  it('renders notification matrix', async () => {
    const view = await renderNotificationsInput()

    checkSimpleTableHeader(view, tableHeaders)
    checkSimpleTableContent(view, tableItems)

    const checkboxes = view.getAllByRole('checkbox')

    expect(checkboxes).toHaveLength(20)
  })

  it('mutates passed value via input events', async () => {
    const view = await renderNotificationsInput({
      value: testValue,
    })

    const checkbox = view.getByLabelText('New ticket - My tickets')

    await view.events.click(checkbox)

    expect(checkbox).not.toBeChecked()

    await waitFor(() => {
      expect(view.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual(
      expect.objectContaining({
        create: expect.objectContaining({
          criteria: expect.objectContaining({ ownedByMe: false }),
        }),
      }),
    )
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/essentials/custom-inputs#input-checklist
describe('Fields - Notifications - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const view = await renderNotificationsInput({
      id: 'test_id',
    })

    expect(view.getByLabelText('Notifications matrix')).toHaveAttribute(
      'id',
      'test_id',
    )
  })

  it('implements input name', async () => {
    const view = await renderNotificationsInput({
      name: 'test_name',
    })

    expect(view.getByLabelText('Notifications matrix')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const view = await renderNotificationsInput({
      onBlur: blurHandler,
    })

    view.getByLabelText('New ticket - My tickets').focus()

    await view.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const view = await renderNotificationsInput()

    const checkbox = view.getByLabelText('New ticket - My tickets')

    await view.events.click(checkbox)

    expect(checkbox).toBeChecked()

    await waitFor(() => {
      expect(view.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual({
      create: { criteria: { ownedByMe: true } },
    })
  })

  it('implements input value display', async () => {
    const view = await renderNotificationsInput({
      value: testValue,
    })

    // Row 1
    expect(view.getByLabelText('New ticket - My tickets')).toBeChecked()
    expect(view.getByLabelText('New ticket - Not assigned')).toBeChecked()
    expect(view.getByLabelText('New ticket - Subscribed tickets')).toBeChecked()
    expect(view.getByLabelText('New ticket - All tickets')).not.toBeChecked()

    expect(
      view.getByLabelText('New ticket - Also notify via email'),
    ).toBeChecked()

    // Row 2
    expect(view.getByLabelText('Ticket update - My tickets')).toBeChecked()
    expect(view.getByLabelText('Ticket update - Not assigned')).toBeChecked()

    expect(
      view.getByLabelText('Ticket update - Subscribed tickets'),
    ).toBeChecked()

    expect(view.getByLabelText('Ticket update - All tickets')).not.toBeChecked()

    expect(
      view.getByLabelText('Ticket update - Also notify via email'),
    ).toBeChecked()

    // Row 3
    expect(
      view.getByLabelText('Ticket reminder reached - My tickets'),
    ).toBeChecked()

    expect(
      view.getByLabelText('Ticket reminder reached - Not assigned'),
    ).not.toBeChecked()

    expect(
      view.getByLabelText('Ticket reminder reached - Subscribed tickets'),
    ).not.toBeChecked()

    expect(
      view.getByLabelText('Ticket reminder reached - All tickets'),
    ).not.toBeChecked()

    expect(
      view.getByLabelText('Ticket reminder reached - Also notify via email'),
    ).toBeChecked()

    // Row 4
    expect(view.getByLabelText('Ticket escalation - My tickets')).toBeChecked()

    expect(
      view.getByLabelText('Ticket escalation - Not assigned'),
    ).not.toBeChecked()

    expect(
      view.getByLabelText('Ticket escalation - Subscribed tickets'),
    ).not.toBeChecked()

    expect(
      view.getByLabelText('Ticket escalation - All tickets'),
    ).not.toBeChecked()

    expect(
      view.getByLabelText('Ticket escalation - Also notify via email'),
    ).toBeChecked()
  })

  it('implements disabled', async () => {
    const view = await renderNotificationsInput({
      disabled: true,
    })

    expect(view.getByLabelText('Notifications matrix')).toBeDisabled()

    const checkboxes = view.getAllByRole('checkbox')

    for (const checkbox of checkboxes) {
      expect(checkbox).toBeDisabled()
    }
  })

  it('implements attribute passthrough', async () => {
    const view = await renderNotificationsInput({
      'test-attribute': 'test_value',
    })

    expect(view.getByLabelText('Notifications matrix')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const view = await renderNotificationsInput()

    expect(view.getByLabelText('Notifications matrix')).toHaveClass(
      'formkit-input',
    )
  })
})
