// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getWrapper } from '@tests/support/components'

const wrapperParameters = {
  form: true,
  formField: true,
}

const wrapper = getWrapper(FormKit, {
  ...wrapperParameters,
  props: {
    name: 'editor',
    type: 'editor',
    id: 'editor',
    label: 'Editor',
  },
  unmount: false,
})

describe('Form - Field - Editor (TipTap)', () => {
  it('can render a editor', () => {
    const editor = wrapper.getByLabelText('Editor')

    expect(editor).toHaveAttribute('contenteditable')

    const node = getNode('editor')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    await wrapper.rerender({
      help: 'This is the help text',
    })

    expect(wrapper.getByText('This is the help text')).toBeInTheDocument()
  })

  // TODO editing with userEvent leads to errors
  it.todo('check for the input event', async () => {
    const editor = wrapper.getByLabelText('Editor')
    await wrapper.events.type(editor, 'H')

    expect(editor).toHaveTextContent('H')
  })
})
