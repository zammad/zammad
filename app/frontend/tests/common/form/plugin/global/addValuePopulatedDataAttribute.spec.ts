// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import * as pluginModule from '@common/form/plugins/global/addValuePopulatedDataAttribute'
import { createNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getWrapper } from '@tests/support/components'
import { waitForTimeout } from '@tests/support/utils'

vi.spyOn(pluginModule, 'default')

const addValuePopulatedDataAttribute = pluginModule.default

const wrapperParameters = {
  form: true,
  formField: true,
}

describe('addValuePopulatedDataAttribute', () => {
  it('check that the plugin can be called with a node', () => {
    const inputNode = createNode({
      type: 'input',
      value: 'Test node',
    })

    addValuePopulatedDataAttribute(inputNode)

    expect(addValuePopulatedDataAttribute).toHaveBeenCalledWith(inputNode)
  })

  describe('check output', () => {
    const wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'text',
        type: 'text',
        id: 'text',
      },
    })

    it('adds value populate data attribute', () => {
      expect(addValuePopulatedDataAttribute).toHaveBeenCalledTimes(1)
      expect(
        wrapper.find('.formkit-outer').attributes()['data-populated'],
      ).toBeUndefined()
    })

    it('is data attribute true when input has a value', async () => {
      expect.assertions(1)
      const input = wrapper.find('input')
      input.setValue('Example title')
      input.trigger('input')

      await waitForTimeout()

      expect(
        wrapper.find('.formkit-outer').attributes()['data-populated'],
      ).toBe('true')
    })
  })
})
