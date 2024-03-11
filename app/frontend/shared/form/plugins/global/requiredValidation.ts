// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode, FormKitProps } from '@formkit/core'

const addRequired = (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  validation: string | Array<[rule: string, ...args: any]>,
) => {
  if (Array.isArray(validation)) {
    if (!validation.includes(['required'])) validation.push(['required'])

    return validation
  }

  if (!validation) {
    return 'required'
  }

  if (!validation.includes('required')) {
    return `${validation}|required`
  }

  return validation
}

const removeRequired = (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  validation: string | Array<[rule: string, ...args: any]>,
) => {
  if (!validation) return validation

  if (Array.isArray(validation)) {
    return validation.filter(([rule]) => rule !== 'required')
  }

  if (validation.includes('required')) {
    return validation
      .split('|')
      .filter((rule: string) => !rule.includes('required'))
      .join('|')
  }

  return validation
}

const addRequiredToValidationProp = (props: Partial<FormKitProps>) => {
  const { validation } = props

  props.validation = addRequired(validation)
}

const removeRequiredFromValidationProp = (props: Partial<FormKitProps>) => {
  const { validation } = props

  props.validation = removeRequired(validation)
}

const addRequiredValidation = (node: FormKitNode) => {
  const { props, context } = node

  if (!props.definition || !context || node.type !== 'input') return

  node.addProps(['required'])

  if (props.required) {
    addRequiredToValidationProp(props)
  }

  node.hook.prop(({ prop, value }, next) => {
    if (prop === 'validation') {
      if (props.required) {
        value = addRequired(value)
      } else {
        value = removeRequired(value)
      }
    }

    return next({ prop, value })
  })

  node.on('prop:required', ({ payload }) => {
    if (payload) {
      addRequiredToValidationProp(props)
    } else {
      removeRequiredFromValidationProp(props)
    }
  })
}

export default addRequiredValidation
