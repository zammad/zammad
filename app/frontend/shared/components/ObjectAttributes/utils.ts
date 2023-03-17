// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'
import { i18n } from '@shared/i18n'

export const translateOption = (
  attribute: ObjectManagerFrontendAttribute,
  str?: string,
) => {
  if (!str) return ''
  if (attribute.dataOption.translate) {
    return i18n.t(str)
  }
  return str
}
