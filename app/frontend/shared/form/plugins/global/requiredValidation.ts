// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const addRequiredValidation = (node: FormKitNode) => {
  node.addProps(['required'])

  const { props } = node

  const addRequired = () => {
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

  const removeRequired = () => {
    const { validation } = props

    if (!validation) {
      return
    }

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

  if (props.required) {
    addRequired()
  }

  node.on('prop:required', ({ payload }) => {
    if (payload) {
      addRequired()
    } else {
      removeRequired()
    }
  })
}

export default addRequiredValidation
