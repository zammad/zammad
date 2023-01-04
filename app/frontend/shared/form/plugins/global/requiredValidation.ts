// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode, FormKitProps } from '@formkit/core'

const addRequired = (props: Partial<FormKitProps>) => {
  const { validation } = props
  if (Array.isArray(validation)) {
    validation.push(['required'])
    return
  }

  if (!validation) {
    props.validation = 'required'
    return
  }

  if (!validation.includes('required')) {
    props.validation = `${validation}|required`
  }
}

const removeRequired = (props: Partial<FormKitProps>) => {
  const { validation } = props

  if (!validation) return

  if (Array.isArray(validation)) {
    props.validation = validation.filter(([rule]) => rule !== 'required')
    return
  }

  if (validation.includes('required')) {
    props.validation = validation
      .split('|')
      .filter((rule: string) => !rule.includes('required'))
      .join('|')
  }
}
const addRequiredValidation = (node: FormKitNode) => {
  const { props, context } = node

  if (!props.definition || !context || node.type !== 'input') return

  node.addProps(['required'])

  if (props.required) {
    addRequired(props)
  }

  node.on('prop:required', ({ payload }) => {
    if (payload) {
      addRequired(props)
    } else {
      removeRequired(props)
    }
  })
}

export default addRequiredValidation
