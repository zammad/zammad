// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

export const getNodeByName = (formId: string, selector: string) => {
  return getNode(`${selector}-${formId}`)
}
