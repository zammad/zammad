// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { i18n } from '#shared/i18n.ts'

export const translateOption = (attribute: ObjectAttribute, str?: string) => {
  if (!str) return ''
  if (attribute.dataOption?.translate) {
    return i18n.t(str)
  }
  return str
}
