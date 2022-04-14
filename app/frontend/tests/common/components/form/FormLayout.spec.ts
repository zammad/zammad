// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FormLayout from '@common/components/form/FormLayout.vue'
import { ExtendedRenderResult, getWrapper } from '@tests/support/components'

describe('FormLayout.vue', () => {
  let wrapper: ExtendedRenderResult

  beforeAll(() => {
    wrapper = getWrapper(FormLayout, {
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
