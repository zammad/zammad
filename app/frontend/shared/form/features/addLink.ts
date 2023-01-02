// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const addLink = (node: FormKitNode) => {
  const { props } = node

  node.addProps(['link'])

  const toggleLink = (isLink: boolean) => {
    props.inputClass = isLink ? 'ltr:pr-2 rtl:pl-2' : undefined
  }

  node.on('created', () => {
    toggleLink(!!props.link)

    node.on('prop:size', ({ payload }) => {
      toggleLink(!!payload)
    })
  })
}

export default addLink
