// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'

const wrapperParameters = {
  form: true,
  formField: true,
}

describe('Form - Field - Group (Formkit-BuildIn)', () => {
  it('empty content without childrens', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'group',
        type: 'group',
        id: 'group',
      },
    })

    expect(wrapper.html()).toBe('')
  })

  it('render some fields and check values', () => {
    const html = String.raw
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'group',
        type: 'group',
        id: 'group',
      },
      slots: {
        default: html`
          <fieldset>
            <FormKit type="text" name="text" id="text" value="example-value" />
            <FormKit
              type="checkbox"
              name="checkbox"
              id="checkbox"
              :value="true"
            />
          </fieldset>
        `,
      },
    })

    const input = wrapper.getByRole('textbox')
    const checkbox = wrapper.getByRole('checkbox')

    expect(input).toBeInTheDocument()
    expect(checkbox).toBeInTheDocument()

    const node = getNode('group')
    expect(node?.value).toStrictEqual({
      text: 'example-value',
      checkbox: true,
    })
  })
})
