// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const addLink = (node: FormKitNode) => {
  node.addProps(['link'])
}

export default addLink
