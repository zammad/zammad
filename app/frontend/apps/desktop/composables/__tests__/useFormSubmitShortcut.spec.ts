// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { markRaw, Teleport, type Component } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import Form from '#shared/components/Form/Form.vue'

import { findFocusedFormNode, useFormSubmitShortcut } from '../useFormSubmitShortcut.ts'

const schema = [
  { type: 'text', name: 'title', label: 'Title' },
  {
    type: 'select',
    name: 'state',
    label: 'State',
    props: { options: [{ value: 1, label: 'open' }] },
  },
  { type: 'date', name: 'due', label: 'Due' },
  {
    type: 'toggleList',
    name: 'roles',
    label: 'Roles',
    props: { options: [{ value: 'agent', label: 'Agent' }] },
  },
  {
    isLayout: true,
    component: 'Teleport',
    props: { to: '#teleport-target' },
    children: [{ type: 'text', name: 'teleported', label: 'Teleported' }],
  },
]

const renderForm = async ({ submitButton = 'enabled' as 'enabled' | 'disabled' | 'none' } = {}) => {
  const onSubmit = vi.fn()

  const wrapper = renderComponent(
    {
      components: { Form },
      template: `
        <div id="teleport-target"></div>
        <Form
          id="shortcut-form"
          :schema="schema"
          :schema-component-library="library"
          @submit="onSubmit"
        />
        <button
          v-if="submitButton !== 'none'"
          type="submit"
          form="shortcut-form"
          :disabled="submitButton === 'disabled'"
        >
          Save
        </button>
        <input aria-label="Outside" />
      `,
      setup: () => {
        useFormSubmitShortcut()

        return {
          schema,
          library: { Teleport: markRaw(Teleport) as unknown as Component },
          onSubmit,
          submitButton,
        }
      },
    },
    { form: true, store: true },
  )

  await getNode('shortcut-form')?.settled

  // The form shows its fields once the initial loading has passed.
  await vi.waitFor(() => expect(wrapper.getByLabelText('Title')).toBeVisible())

  return { wrapper, onSubmit }
}

const focusField = (name: string) => {
  const id = getNode('shortcut-form')?.find(name, 'name')?.props.id

  if (id) document.getElementById(id)?.focus()
}

describe('useFormSubmitShortcut', () => {
  it.each([
    ['a text field', 'title'],
    ['a select', 'state'],
    ['a date field', 'due'],
    ['a field rendered outside the form element', 'teleported'],
  ])('submits the form with ctrl+enter from %s', async (_, field) => {
    const { wrapper, onSubmit } = await renderForm()

    focusField(field)

    expect(findFocusedFormNode()?.props.id).toBe('shortcut-form')

    await wrapper.events.keyboard('{Control>}{Enter}{/Control}')

    await vi.waitFor(() => expect(onSubmit).toHaveBeenCalledOnce())
  })

  it('submits the form with ctrl+enter from an input a field renders as a node of its own', async () => {
    const { wrapper, onSubmit } = await renderForm()

    wrapper.getByRole('switch', { name: 'Agent' }).focus()

    expect(findFocusedFormNode()?.props.id).toBe('shortcut-form')

    await wrapper.events.keyboard('{Control>}{Enter}{/Control}')

    await vi.waitFor(() => expect(onSubmit).toHaveBeenCalledOnce())
  })

  it('does not submit a form whose submit button is disabled', async () => {
    const { wrapper, onSubmit } = await renderForm({ submitButton: 'disabled' })

    focusField('title')
    await wrapper.events.keyboard('{Control>}{Enter}{/Control}')
    await getNode('shortcut-form')?.settled

    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('does not submit a form without a submit button', async () => {
    const { wrapper, onSubmit } = await renderForm({ submitButton: 'none' })

    focusField('title')
    await wrapper.events.keyboard('{Control>}{Enter}{/Control}')
    await getNode('shortcut-form')?.settled

    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('does nothing outside a form', async () => {
    const { wrapper, onSubmit } = await renderForm()

    wrapper.getByLabelText('Outside').focus()

    expect(findFocusedFormNode()).toBeUndefined()

    await wrapper.events.keyboard('{Control>}{Enter}{/Control}')
    await getNode('shortcut-form')?.settled

    expect(onSubmit).not.toHaveBeenCalled()
  })
})
