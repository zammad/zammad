// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

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
