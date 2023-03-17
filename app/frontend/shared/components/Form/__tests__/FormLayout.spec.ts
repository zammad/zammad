// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import FormLayout from '@shared/components/Form/FormLayout.vue'
import type { ExtendedRenderResult } from '@tests/support/components'
import { renderComponent } from '@tests/support/components'

describe('FormLayout.vue', () => {
  let wrapper: ExtendedRenderResult

  beforeAll(() => {
    wrapper = renderComponent(FormLayout, {
      props: {},
      slots: {
        default: 'Should be a field',
      },
    })
  })

  it('check the output', () => {
    const fieldset = wrapper.getByRole('group')
    expect(fieldset).toBeInTheDocument()
    expect(fieldset).toHaveTextContent('Should be a field')
    expect(fieldset).toHaveClass('column-1')
  })

  // TODO: more real live test cases with fields, when the component usage is more clear.
})
