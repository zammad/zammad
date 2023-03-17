// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitFrameworkContext } from '@formkit/core'
import { createNode } from '@formkit/core'
import requiredValidation from '../global/requiredValidation'

const createInput = (props: any = {}) => {
  const originalSchema = vi.fn()
  const inputNode = createNode({
    type: 'input',
    value: 'Test node',
    props: {
      definition: { type: 'input', schema: originalSchema },
      ...props,
    },
  })

  inputNode.context = {
    fns: {},
  } as FormKitFrameworkContext

  return inputNode
}

describe('requiredValidation', () => {
  it('doesnt add validation rule', () => {
    const inputNode = createInput({})

    requiredValidation(inputNode)

    expect(inputNode.props.validation).not.toBe('required')
  })

  it('adds validation rule', () => {
    const inputNode = createInput({
      required: true,
    })

    requiredValidation(inputNode)

    expect(inputNode.props.validation).toBe('required')
  })

  it('appends validation rule to string', () => {
    const inputNode = createInput({
      required: true,
      validation: 'number',
    })

    requiredValidation(inputNode)

    expect(inputNode.props.validation).toBe('number|required')
  })

  it('appends validation rule to array', () => {
    const inputNode = createInput({
      required: true,
      validation: [['number']],
    })

    requiredValidation(inputNode)

    expect(inputNode.props.validation).toEqual([['number'], ['required']])
  })

  it('required prop removed from input', () => {
    const inputNode = createInput({
      required: true,
      validation: [['number']],
    })

    requiredValidation(inputNode)

    inputNode.emit('prop:required', false)

    expect(inputNode.props.validation).toEqual([['number']])
  })

  it('required prop removed from string', () => {
    const inputNode = createInput({
      required: true,
      validation: 'number',
    })

    requiredValidation(inputNode)

    inputNode.emit('prop:required', false)

    expect(inputNode.props.validation).toBe('number')
  })
})
