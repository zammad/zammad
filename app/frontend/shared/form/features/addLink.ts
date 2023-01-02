// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const addLink = (node: FormKitNode) => {
  const { props } = node

  node.addProps(['link'])

  const toggleLink = (isLink: boolean) => {
    if (isLink) {
      props.inputClass = `${props.inputClass} ltr:pr-2 rtl:pl-2`
    } else if (props.inputClass) {
      props.inputClass = props.inputClass.replace('ltr:pr-2 rtl:pl-2', '')
    }
  }

  node.on('created', () => {
    toggleLink(!!props.link)

    node.on('prop:link', ({ payload }) => {
      toggleLink(!!payload)
    })
  })
}

export default addLink
