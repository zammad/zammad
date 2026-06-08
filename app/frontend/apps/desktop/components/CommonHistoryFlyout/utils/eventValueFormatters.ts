// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { EnumObjectManagerObjects, type HistoryRecordEvent } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import { isDateString } from '#shared/utils/datetime.ts'

import { getEntityFromObject } from './eventHelpers.ts'

const getObjectAttribute = (event: DeepPartial<HistoryRecordEvent>) => {
  const { attribute: attributeName } = event
  if (!attributeName) return undefined

  const entity = getEntityFromObject(event.object)

  if (entity in EnumObjectManagerObjects) {
    const { attributesLookup: objectAttributesLookup } = useObjectAttributes(
      EnumObjectManagerObjects[entity as keyof typeof EnumObjectManagerObjects],
    )

    return (
      objectAttributesLookup.value.get(`${attributeName}_id`) ??
      objectAttributesLookup.value.get(attributeName)
    )
  }

  return undefined
}

export const getDisplayName = (event: DeepPartial<HistoryRecordEvent>) => {
  const objectAttribute = getObjectAttribute(event)
  if (objectAttribute) {
    return objectAttribute.display
  }

  return event.attribute
}

export const attributeNeedsTranslation = (event: DeepPartial<HistoryRecordEvent>) => {
  let needsTranslation = false

  const objectAttribute = getObjectAttribute(event)
  if (objectAttribute) {
    needsTranslation = objectAttribute?.dataOption?.translate ?? false
  }
  return needsTranslation
}

export const formatDateOrDateTime = (value: string) => {
  const dateFormatFunction = isDateString(value) ? 'date' : 'dateTime'
  if (value !== '-') {
    value = i18n[dateFormatFunction](value)
  }
  return value
}

export const formatGroup = (attributeName: Maybe<string> | undefined, attributeValue: string) => {
  if (!attributeName) return attributeValue
  if (attributeName !== 'group') return attributeValue

  return attributeValue.replace(/::/g, ' › ')
}
