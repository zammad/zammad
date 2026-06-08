// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitUntil, waitForNextTick } from '#tests/support/utils.ts'

import Form from '#shared/components/Form/Form.vue'

const renderForm = async (
  schema: Record<string, unknown>[],
  changeFields?: Record<string, Record<string, unknown>>,
) => {
  const wrapper = renderComponent(Form, {
    form: true,
    router: true,
    attachTo: document.body,
    props: {
      id: 'test-form',
      schema,
      changeFields,
    },
  })

  await waitUntil(() => wrapper.emitted().settled)

  return wrapper
}

const getFormNode = () => getNode('test-form')

describe('initializeFieldInitialValuesCleanupPlugin', () => {
  it('does not report dirty when a visible field is removed', async () => {
    const wrapper = await renderForm([
      {
        type: 'text',
        name: 'title',
        label: 'Title',
        value: 'Test',
      },
      {
        type: 'text',
        name: 'dynamic',
        label: 'Dynamic',
        value: 'Initial',
      },
    ])

    const formNode = getFormNode()
    expect(formNode?.context?.state.dirty).toBe(false)

    // Hide the dynamic field via changeFields (simulates core workflow).
    await wrapper.rerender({
      changeFields: { dynamic: { show: false } },
    })
    await waitForNextTick()

    expect(wrapper.queryByLabelText('Dynamic')).not.toBeInTheDocument()
    expect(formNode?.context?.state.dirty).toBe(false)
  })

  it('does not report dirty when a removed field is re-added', async () => {
    const wrapper = await renderForm([
      {
        type: 'text',
        name: 'title',
        label: 'Title',
        value: 'Test',
      },
      {
        type: 'text',
        name: 'dynamic',
        label: 'Dynamic',
        value: 'Initial',
      },
    ])

    const formNode = getFormNode()

    // Remove the field.
    await wrapper.rerender({
      changeFields: { dynamic: { show: false } },
    })
    await waitForNextTick()

    expect(formNode?.context?.state.dirty).toBe(false)

    // Show the field again.
    await wrapper.rerender({
      changeFields: { dynamic: { show: true } },
    })
    await waitForNextTick()

    expect(wrapper.queryByLabelText('Dynamic')).toBeInTheDocument()
    expect(formNode?.context?.state.dirty).toBe(false)
  })

  it('does not report dirty when a field inside a group is removed', async () => {
    const wrapper = await renderForm([
      {
        type: 'text',
        name: 'title',
        label: 'Title',
        value: 'Test',
      },
      {
        isGroupOrList: true,
        type: 'group',
        name: 'details',
        children: [
          {
            type: 'text',
            name: 'dynamic',
            label: 'Dynamic',
            value: 'Nested',
          },
        ],
      },
    ])

    const formNode = getFormNode()
    expect(formNode?.context?.state.dirty).toBe(false)

    // Remove the nested field.
    await wrapper.rerender({
      changeFields: { dynamic: { show: false } },
    })
    await waitForNextTick()

    expect(wrapper.queryByLabelText('Dynamic')).not.toBeInTheDocument()

    // Both the group and form should not be dirty.
    expect(formNode?.context?.state.dirty).toBe(false)
  })

  it('does not report dirty when a field is shown after a reset that included its value', async () => {
    // Regression: another user changes a value → subscription update triggers
    // resetForm(newValues, { resetDirty: false }). FormKit's reset() stores the
    // full resetTo value in form._init — including hidden fields. When the form-
    // updater then shows the field, its child value (hydrated from the parent's
    // live _value, which dropped the hidden field) may differ from what reset()
    // left in _init, causing a false dirty state.
    const wrapper = await renderForm(
      [
        {
          type: 'text',
          name: 'title',
          label: 'Title',
          value: 'Test',
        },
        {
          type: 'text',
          name: 'dynamic',
          label: 'Dynamic',
          value: '',
        },
      ],
      { dynamic: { show: false } },
    )

    const formNode = getFormNode()
    expect(formNode?.context?.state.dirty).toBe(false)

    // Simulate the subscription-update reset: reset() sets _init at the root
    // level from the full server values, including hidden fields. This mimics
    // what resetForm({ values: serverValues }, { resetDirty: false }) does.
    formNode?.reset({ title: 'Test', dynamic: 'ServerValue' })
    await waitForNextTick()

    // Simulate form-updater showing the field (after the subscription update
    // triggers a form-updater refresh). The field shows with its schema default
    // value ('') because the parent's _value dropped the hidden field's pending
    // value during the reset.
    await wrapper.rerender({ changeFields: { dynamic: { show: true } } })
    await formNode?.settled
    await waitForNextTick()

    expect(wrapper.queryByLabelText('Dynamic')).toBeInTheDocument()
    expect(formNode?.context?.state.dirty).toBe(false)
  })

  it('does not report dirty when a previously hidden field is shown', async () => {
    // Field starts hidden and is then shown — simulates a field that only
    // appears after a core workflow response.
    const wrapper = await renderForm(
      [
        {
          type: 'text',
          name: 'title',
          label: 'Title',
          value: 'Test',
        },
        {
          type: 'text',
          name: 'dynamic',
          label: 'Dynamic',
          value: 'Revealed',
        },
      ],
      { dynamic: { show: false } },
    )

    const formNode = getFormNode()
    expect(wrapper.queryByLabelText('Dynamic')).not.toBeInTheDocument()
    expect(formNode?.context?.state.dirty).toBe(false)

    // Show the field (simulates form-updater showing it).
    await wrapper.rerender({
      changeFields: { dynamic: { show: true } },
    })

    // Wait for the child to settle and _init sync to propagate.
    await formNode?.settled
    await waitForNextTick()

    expect(wrapper.queryByLabelText('Dynamic')).toBeInTheDocument()
    expect(formNode?.context?.state.dirty).toBe(false)
  })
})
