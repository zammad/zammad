// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { useEntity } from '#shared/entities/useEntity.ts'
import type { ObjectAttributeValue } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import type { EntityObject } from '#shared/types/entity.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { camelize } from '#shared/utils/formatter.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

import type { Dictionary } from 'ts-essentials'

export const getValue = (
  key: string,
  object: ObjectLike,
  attributesObject: Dictionary<ObjectAttributeValue>,
  attribute: ObjectAttribute,
) => {
  if (attribute.dataOption?.relation) {
    const entityName = attribute.dataOption.relation
    const belongsTo = attribute.dataOption.belongs_to || camelize(entityName)

    const entity = useEntity(entityName)
    const entityObject = object[belongsTo]

    if (entity && entityObject) {
      // Special handling for array relations (e.g. secondary organizations)
      if ('edges' in entityObject) {
        return edgesToArray(entityObject)
          .map((item) => entity.display(item as EntityObject))
          .join(', ')
      }

      return entity.display(entityObject)
    }
  }

  if (key in attributesObject) {
    return attributesObject[key].value
  }
  if (key in object) {
    return object[key]
  }
  return object[camelize(key)]
}

export const isEmpty = (value: unknown) => {
  if (Array.isArray(value)) {
    return value.length === 0
  }
  if (value && typeof value === 'object') {
    return Object.keys(value).length === 0
  }

  return value === null || value === undefined || value === ''
}

export const getLink = (
  name: string,
  attributesObject: Dictionary<ObjectAttributeValue>,
) => {
  const attribute = attributesObject[name]
  return attribute?.renderedLink || null
}

export const translateOption = (attribute: ObjectAttribute, str?: string) => {
  if (!str) return ''

  if (attribute.dataOption?.translate) {
    return i18n.t(str)
  }
  return str
}
