// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { nextTick } from 'vue'

const wrapperParameters = {
  form: true,
  formField: true,
}

// Only some small initialize test, because the real editor testing is inside of cypress.
describe('Form - Field - Editor (TipTap)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'editor',
      type: 'editor',
      id: 'editor',
      label: 'Editor',
    },
    unmount: false,
  })

  it('can render an editor', async () => {
    const editor = await wrapper.findByTestId(
      'field-editor',
      {},
      { timeout: 5000 },
    )

    await nextTick()

    expect(editor.children[0]).toHaveAttribute('contenteditable')

    const node = getNode('editor')
    expect(node?.value).toBe(undefined)
  }, 5000)

  it('set some props', async () => {
    await wrapper.rerender({
      help: 'This is the help text',
    })

    expect(wrapper.getByText('This is the help text')).toBeInTheDocument()
  })
})
