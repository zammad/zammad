// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitUntil } from '#tests/support/utils.ts'

import Form from '#shared/components/Form/Form.vue'
import UserError from '#shared/errors/UserError.ts'

import { setErrors } from '../utils.ts'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
  unmount: true,
}

describe('setErrors', () => {
  it('routes a field error to a field nested inside a FormKit group node', async () => {
    const wrapper = renderComponent(Form, {
      ...wrapperParameters,
      attrs: { id: 'test-form' },
      props: {
        schema: [
          {
            type: 'group',
            name: 'step',
            children: [{ type: 'text', name: 'title', label: 'Title' }],
          },
        ],
      },
    })

    await waitUntil(() => wrapper.emitted().settled)

    const formNode = getNode('test-form')!
    setErrors(formNode, new UserError([{ field: 'title', message: 'Title must be unique.' }]))

    await waitFor(() => {
      expect(wrapper.getByText('Title must be unique.')).toBeInTheDocument()
    })

    // The error must live on the field node itself — not as an unresolved input
    // error on the form root, which would keep the submit button disabled with
    // no visible feedback for the user.
    expect(formNode.find('title', 'name')?.context?.state.errors).toBe(true)
  })

  it('sets general errors (no field) on the form node itself', async () => {
    const wrapper = renderComponent(Form, {
      ...wrapperParameters,
      attrs: { id: 'test-form' },
      props: {
        schema: [{ type: 'text', name: 'title', label: 'Title' }],
      },
    })

    await waitUntil(() => wrapper.emitted().settled)

    const formNode = getNode('test-form')!
    setErrors(formNode, new UserError([{ message: 'Something went wrong.' }]))

    await waitFor(() => {
      expect(wrapper.getByText('Something went wrong.')).toBeInTheDocument()
    })

    expect(formNode.context?.state.errors).toBe(true)
  })
})
