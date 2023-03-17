// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getAllByRole } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'

const wrapperParameters = {
  form: true,
  formField: true,
}

describe('Form - Field - List (Formkit-BuildIn)', () => {
  it('empty content without childrens', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'list',
        type: 'list',
        id: 'list',
      },
    })

    expect(wrapper.html()).toBe('')
  })

  it('render some fields and check values', () => {
    const html = String.raw
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'list',
        type: 'list',
        id: 'list',
      },
      slots: {
        default: html`
          <fieldset>
            <FormKit
              type="text"
              name="email-adress"
              id="text"
              value="admin@example.com"
            />
            <FormKit
              type="text"
              name="email-adress"
              id="text"
              value="admin2@example.com"
            />
          </fieldset>
        `,
      },
    })

    const group = wrapper.getByRole('group')
    const inputs = getAllByRole(group, 'textbox')

    expect(inputs).toHaveLength(2)

    const node = getNode('list')
    expect(node?.value).toStrictEqual([
      'admin@example.com',
      'admin2@example.com',
    ])
  })
})
