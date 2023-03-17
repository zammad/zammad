// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormKitExtendableSchemaRoot,
  FormKitFrameworkContext,
} from '@formkit/core'
import { createNode, getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { waitForNextTick } from '@tests/support/utils'
import extendDataAttribues from '../global/extendDataAttributes'

const wrapperParameters = {
  form: true,
  formField: true,
}

const renderKit = (props: any = {}) => {
  const kit = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'text',
      type: 'text',
      id: 'text',
      label: 'text',
      ...props,
    },
  })
  return {
    ...kit,
    getOuterKit: () => kit.container.querySelector('.formkit-outer'),
  }
}

describe('extendDataAttributes - data-populated', () => {
  describe('renders on output', () => {
    const originalSchema = vi.fn()
    const inputNode = createNode({
      type: 'input',
      value: 'Test node',
      props: {
        definition: { type: 'input', schema: originalSchema },
      },
    })

    inputNode.context = {
      fns: {},
    } as FormKitFrameworkContext

    beforeEach(() => {
      originalSchema.mockReset()
    })

    it('applies schema on input', () => {
      extendDataAttribues(inputNode)

      const schema = (inputNode.props.definition?.schema ||
        (() => ({}))) as FormKitExtendableSchemaRoot

      schema({})

      expect(originalSchema.mock.calls[0][0]).toHaveProperty(
        'outer.attrs.data-populated',
      )
    })

    it('skips non-inputs', () => {
      extendDataAttribues({
        ...inputNode,
        type: 'list',
      })

      expect(originalSchema).not.toHaveBeenCalled()
    })
  })

  describe('check output', () => {
    it('adds value populate data attribute', () => {
      const kit = renderKit()
      expect(kit.getOuterKit()).not.toHaveAttribute('data-populated')
    })

    it('is data attribute true when input has a value', async () => {
      const kit = renderKit()

      const input = kit.getByLabelText('text')
      expect(kit.getOuterKit()).not.toHaveAttribute('data-populated')

      await kit.events.type(input, 'input')

      expect(kit.getOuterKit()).toHaveAttribute('data-populated')

      await kit.events.clear(input)

      expect(kit.getOuterKit()).not.toHaveAttribute('data-populated')
    })

    it('is data attribute true when input has an initial value', async () => {
      const kit = renderKit({
        value: 'abc',
      })

      expect(kit.getOuterKit()).toHaveAttribute('data-populated')
    })

    it('is data attribute true for number input with zero', async () => {
      const kit = renderKit({
        name: 'number',
        type: 'number',
        id: 'number',
        label: 'number',
      })

      const node = getNode('number')
      node?.input(0)

      await waitForNextTick(true)

      expect(kit.getOuterKit()).toHaveAttribute('data-populated')
    })

    it('is data attribute true for a false boolean value', async () => {
      const kit = renderKit({
        name: 'checkbox',
        type: 'checkbox',
        id: 'checkbox',
        label: 'checkbox',
      })

      const node = getNode('checkbox')
      node?.input(false)

      await waitForNextTick(true)

      expect(kit.getOuterKit()).toHaveAttribute('data-populated')
    })
  })
})

describe('extendDataAttributes - data-required', () => {
  it('has data-required if field is required', () => {
    const kit = renderKit({
      required: true,
    })
    expect(kit.getOuterKit()).toHaveAttribute('data-required')
  })
})
